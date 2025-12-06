import Foundation
import Combine
import OSLog

final class WebSocketManager: NSObject {
    static let shared = WebSocketManager()

    private let url = URL(string: "wss://ws.postman-echo.com/raw")!
    private var session: URLSession
    private var task: URLSessionWebSocketTask?
    private var sendTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var priceBook: [String: Double] = [:]
    private var symbolsToStream: [StockSymbol] = []

    let updates = PassthroughSubject<PriceUpdate, Never>()
    let connectionStatus = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    override init() {
        // Create a session that reports WebSocket delegate callbacks.
        self.session = URLSession(configuration: .default)
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(with symbols: [StockSymbol]) {
        // Ensure a clean slate before connecting.
        disconnect()

        connectionStatus.send(.connecting)
        symbolsToStream = symbols

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        // Do NOT mark .connected or start send/ping/receive yet.
        // We’ll do that in didOpen.
    }

    func disconnect() {
        sendTask?.cancel()
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        sendTask = nil
        heartbeatTask = nil
        receiveTask = nil

        task?.cancel(with: .goingAway, reason: nil)
        task = nil

        connectionStatus.send(.disconnected)
    }

    private func logError(_ message: String) {
        Logger.networking.error("\(message, privacy: .public)")
    }

    private func logAndDisconnect(_ message: String) {
        logError(message)
        disconnect()
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
                    try await Task.sleep(nanoseconds: 2_000_000_000)
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
                    try await Task.sleep(nanoseconds: 15_000_000_000)
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
        // Handshake completed — it’s safe to send and ping now.
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
        // Clean up and report a user-friendly status.
        sendTask?.cancel()
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        task = nil

        let textReason: String? = reason
            .flatMap { String(data: $0, encoding: .utf8) }
            .flatMap { $0.isEmpty ? nil : $0}

        switch (textReason, closeCode) {
        case let (.some(message), _):
            logError("Socket closed with reason: \(message)")
            connectionStatus.send(.disconnected)

        case (nil, .normalClosure), (nil, .goingAway):
            connectionStatus.send(.disconnected)

        default:
            logError("Socket closed with code: \(closeCode.rawValue)")
            connectionStatus.send(.disconnected)
        }
    }
}
