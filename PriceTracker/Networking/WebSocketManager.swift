import Foundation
import Combine
import OSLog

final class WebSocketManager: NSObject, WebSocketManaging {
    static let shared = WebSocketManager()

    private let url: URL
    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    private var sendTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var priceBook: [String: Double] = [:]
    private var symbolsToStream: [StockSymbol] = []
    private var reconnectAttempt: Int = 0
    private var isUserInitiatedDisconnect: Bool = false

    let updates = PassthroughSubject<PriceUpdate, Never>()
    let connectionStatus = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    override init() {
        guard let url = URL(string: "wss://ws.postman-echo.com/raw") else {
            fatalError("Invalid WebSocket URL configuration")
        }
        self.url = url
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(with symbols: [StockSymbol]) {
        isUserInitiatedDisconnect = false
        reconnectAttempt = 0
        reconnectTask?.cancel()
        reconnectTask = nil

        cancelActiveTasks()

        connectionStatus.send(.connecting)
        symbolsToStream = symbols

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
    }

    func disconnect() {
        isUserInitiatedDisconnect = true
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempt = 0

        cancelActiveTasks()

        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        connectionStatus.send(.disconnected)
    }

    private func cancelActiveTasks() {
        sendTask?.cancel()
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        sendTask = nil
        heartbeatTask = nil
        receiveTask = nil
    }

    private func scheduleReconnect() {
        guard !isUserInitiatedDisconnect else { return }
        guard reconnectAttempt < Constants.maxReconnectAttempts else {
            logError("Max reconnection attempts reached")
            connectionStatus.send(.disconnected)
            return
        }

        reconnectAttempt += 1
        let attempt = reconnectAttempt
        connectionStatus.send(.reconnecting(attempt: attempt))

        let delay = min(
            Constants.initialReconnectDelay * pow(2.0, Double(attempt - 1)),
            Constants.maxReconnectDelay
        )

        Logger.networking.info("Scheduling reconnect attempt \(attempt) in \(delay)s")

        reconnectTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self, !Task.isCancelled else { return }
                self.performReconnect()
            } catch {
                // Task cancelled
            }
        }
    }

    private func performReconnect() {
        guard !symbolsToStream.isEmpty else { return }

        cancelActiveTasks()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        let newTask = session.webSocketTask(with: url)
        self.task = newTask
        newTask.resume()
    }

    private func logError(_ message: String) {
        Logger.networking.error("\(message, privacy: .public)")
    }

    private func logAndDisconnect(_ message: String, attemptReconnect: Bool = true) {
        logError(message)
        cancelActiveTasks()
        task?.cancel(with: .abnormalClosure, reason: nil)
        task = nil

        if attemptReconnect {
            scheduleReconnect()
        } else {
            connectionStatus.send(.disconnected)
        }
    }

    private func configureInitialPrices(for symbols: [StockSymbol]) {
        for symbol in symbols {
            priceBook[symbol.ticker] = priceBook[symbol.ticker] ?? Double.random(in: 40...250)
        }
    }

    private func startSendingUpdates(_ symbols: [StockSymbol]) {
        sendTask?.cancel()
        sendTask = Task { [weak self] in
            guard let self else { return }
            do {
                while !Task.isCancelled {
                    await self.broadcastUpdates(for: symbols)
                    try await Task.sleep(nanoseconds: Constants.priceUpdateInterval)
                }
            } catch is CancellationError {
                return
            } catch {
                self.logAndDisconnect("Send loop error: \(error.localizedDescription)")
            }
        }
    }

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            guard let self else { return }

            do {
                while !Task.isCancelled {
                    try await self.sendPing()
                    try await Task.sleep(nanoseconds: Constants.heartbeatInterval)
                }
            } catch is CancellationError {
                return
            } catch {
                self.logAndDisconnect("Heartbeat error: \(error.localizedDescription)")
            }
        }
    }

    private func startReceiving() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    guard let message = try await self.task?.receive() else { return }
                    self.handle(message)
                } catch is CancellationError {
                    return
                } catch {
                    self.logAndDisconnect("Receive loop error: \(error.localizedDescription)")
                    return
                }
            }
        }
    }

    private func broadcastUpdates(for symbols: [StockSymbol]) async {
        for symbol in symbols {
            let existingPrice = priceBook[symbol.ticker] ?? Double.random(in: 40...250)
            let delta = Double.random(in: -2.5...2.5)
            let updatedPrice = max(0.5, existingPrice + delta)
            priceBook[symbol.ticker] = updatedPrice

            let update = PriceUpdate(symbol: symbol.ticker, price: updatedPrice, change: delta)
            updates.send(update)
            await sendMessage(update)
        }
    }

    private func sendMessage(_ update: PriceUpdate) async {
        guard let task = task else { return }
        let payload: [String: Any] = [
            "symbol": update.symbol,
            "price": update.price,
            "change": update.change,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let text = String(data: data, encoding: .utf8) {
            do {
                try await task.send(.string(text))
            } catch {
                logAndDisconnect("Send failed: \(error.localizedDescription)")
            }
        }
    }

    private func sendPing() async throws {
        guard let task = task else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        // The echo server mirrors outbound messages; we don't need the response to update UI.
        // This keeps the receive loop alive and surfaces failures through connectionStatus.
        if case let .string(text) = message,
           text.contains("disconnect") {
            logAndDisconnect("Server requested disconnect: \(text)")
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol `protocol`: String?) {
        // Handshake completed — reset reconnect state and start operations.
        reconnectAttempt = 0
        connectionStatus.send(.connected)
        configureInitialPrices(for: symbolsToStream)
        startSendingUpdates(symbolsToStream)
        startHeartbeat()
        startReceiving()
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode:
        URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        cancelActiveTasks()
        task = nil

        let textReason: String? = reason
            .flatMap { String(data: $0, encoding: .utf8) }
            .flatMap { $0.isEmpty ? nil : $0 }

        let shouldReconnect: Bool

        switch (textReason, closeCode) {
        case let (.some(message), _):
            logError("Socket closed with reason: \(message)")
            shouldReconnect = false

        case (nil, .normalClosure), (nil, .goingAway):
            shouldReconnect = false

        default:
            logError("Socket closed with code: \(closeCode.rawValue)")
            shouldReconnect = true
        }

        if shouldReconnect {
            scheduleReconnect()
        } else {
            connectionStatus.send(.disconnected)
        }
    }
}
