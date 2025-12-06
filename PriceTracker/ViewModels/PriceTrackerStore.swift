import Combine
import Foundation

struct AppState: Equatable {
    let symbols: [StockSymbol]
    let prices: [String: PriceUpdate]
    let connectionState: ConnectionState
    let selectedSymbol: StockSymbol?
    let flashes: [String: PriceFlash]

    init(
        symbols: [StockSymbol],
        prices: [String: PriceUpdate] = [:],
        connectionState: ConnectionState = .disconnected,
        selectedSymbol: StockSymbol? = nil,
        flashes: [String: PriceFlash] = [:]
    ) {
        self.symbols = symbols
        self.prices = prices
        self.connectionState = connectionState
        self.selectedSymbol = selectedSymbol
        self.flashes = flashes
    }

    func updatingConnection(_ newValue: ConnectionState) -> AppState {
        AppState(
            symbols: symbols,
            prices: prices,
            connectionState: newValue,
            selectedSymbol: selectedSymbol,
            flashes: flashes
        )
    }

    func applying(_ update: PriceUpdate) -> AppState {
        var nextPrices = prices
        nextPrices[update.symbol] = update
        var nextFlashes = flashes
        if update.change != 0 {
            nextFlashes[update.symbol] = update.change >= 0 ? .up : .down
        }
        return AppState(
            symbols: symbols,
            prices: nextPrices,
            connectionState: connectionState,
            selectedSymbol: selectedSymbol,
            flashes: nextFlashes
        )
    }

    func selecting(_ symbol: StockSymbol) -> AppState {
        AppState(
            symbols: symbols,
            prices: prices,
            connectionState: connectionState,
            selectedSymbol: symbol,
            flashes: flashes
        )
    }

    func clearingFlash(for symbol: String) -> AppState {
        var nextFlashes = flashes
        nextFlashes[symbol] = nil
        return AppState(
            symbols: symbols,
            prices: prices,
            connectionState: connectionState,
            selectedSymbol: selectedSymbol,
            flashes: nextFlashes
        )
    }
}

@MainActor
final class PriceTrackerStore: ObservableObject {
    @Published private(set) var state: AppState

    private let webSocketManager: WebSocketManager
    private var cancellables: Set<AnyCancellable> = []
    private var flashTasks: [String: Task<Void, Never>] = [:]

    init(webSocketManager: WebSocketManager = .shared, symbols: [StockSymbol] = StockSymbol.demoSymbols) {
        self.webSocketManager = webSocketManager
        state = AppState(symbols: symbols, selectedSymbol: symbols.first)
        bind()
    }

    func startStreaming() {
        webSocketManager.connect(with: state.symbols)
    }

    func stopStreaming() {
        webSocketManager.disconnect()
        flashTasks.values.forEach { $0.cancel() }
        flashTasks.removeAll()
        state = state.updatingConnection(.disconnected)
    }

    func select(symbol: StockSymbol) {
        state = state.selecting(symbol)
    }

    private func bind() {
        webSocketManager.connectionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] newStatus in
                guard let self else { return }
                self.state = self.state.updatingConnection(newStatus)
            }
            .store(in: &cancellables)

        webSocketManager.updates
            .receive(on: RunLoop.main)
            .sink { [weak self] update in
                guard let self else { return }
                self.state = self.state.applying(update)
                self.scheduleFlashClear(for: update.symbol)
            }
            .store(in: &cancellables)
    }

    private func scheduleFlashClear(for symbol: String) {
        flashTasks[symbol]?.cancel()
        flashTasks[symbol] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                guard let self else { return }
                self.state = self.state.clearingFlash(for: symbol)
                self.flashTasks[symbol] = nil
            }
        }
    }
}
