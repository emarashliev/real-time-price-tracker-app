import Combine
import Foundation

struct AppState: Equatable {
    let symbols: [StockSymbol]
    let symbolsByTicker: [String: StockSymbol]
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
        precondition(!symbols.isEmpty, "AppState requires at least one symbol")
        self.symbols = symbols
        self.symbolsByTicker = Dictionary(uniqueKeysWithValues: symbols.map { ($0.ticker, $0) })
        self.prices = prices
        self.connectionState = connectionState
        self.selectedSymbol = selectedSymbol
        self.flashes = flashes
    }

    private init(
        symbols: [StockSymbol],
        symbolsByTicker: [String: StockSymbol],
        prices: [String: PriceUpdate],
        connectionState: ConnectionState,
        selectedSymbol: StockSymbol?,
        flashes: [String: PriceFlash]
    ) {
        self.symbols = symbols
        self.symbolsByTicker = symbolsByTicker
        self.prices = prices
        self.connectionState = connectionState
        self.selectedSymbol = selectedSymbol
        self.flashes = flashes
    }

    func updatingConnection(_ newValue: ConnectionState) -> AppState {
        AppState(
            symbols: symbols,
            symbolsByTicker: symbolsByTicker,
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
        if abs(update.change) > 0.001 {
            nextFlashes[update.symbol] = update.change >= 0 ? .up : .down
        }
        return AppState(
            symbols: symbols,
            symbolsByTicker: symbolsByTicker,
            prices: nextPrices,
            connectionState: connectionState,
            selectedSymbol: selectedSymbol,
            flashes: nextFlashes
        )
    }

    func selecting(_ symbol: StockSymbol) -> AppState {
        AppState(
            symbols: symbols,
            symbolsByTicker: symbolsByTicker,
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
            symbolsByTicker: symbolsByTicker,
            prices: prices,
            connectionState: connectionState,
            selectedSymbol: selectedSymbol,
            flashes: nextFlashes
        )
    }

    func symbol(for ticker: String) -> StockSymbol? {
        symbolsByTicker[ticker]
    }
}

@MainActor
final class PriceTrackerStore: ObservableObject {
    @Published private(set) var state: AppState

    private let webSocketManager: WebSocketManaging
    private var cancellables: Set<AnyCancellable> = []
    private var flashTasks: [String: Task<Void, Never>] = [:]

    init(webSocketManager: WebSocketManaging = WebSocketManager.shared, symbols: [StockSymbol] = StockSymbol.demoSymbols) {
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
            try? await Task.sleep(nanoseconds: Constants.flashDuration)
            await MainActor.run {
                guard let self else { return }
                self.state = self.state.clearingFlash(for: symbol)
                self.flashTasks[symbol] = nil
            }
        }
    }
}
