import Testing
@testable import PriceTracker

@MainActor
@Suite("DetailViewModel Tests")
struct DetailViewModelTests {
    let testSymbols = [
        StockSymbol(symbol: "AAA", name: "Company A", description: "Test A"),
        StockSymbol(symbol: "BBB", name: "Company B", description: "Test B")
    ]

    @Test("Initial state has placeholder values")
    func initialStateHasPlaceholderValues() {
        let viewModel = DetailViewModel()

        #expect(viewModel.state.symbol == "--")
        #expect(viewModel.state.name == "--")
        #expect(viewModel.state.priceText == "$--")
    }

    @Test("Configure sets target symbol state")
    func configureSetsTargetSymbolState() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[1]

        viewModel.configure(with: store, symbol: targetSymbol)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.symbol == "BBB")
        #expect(viewModel.state.name == "Company B")
        #expect(viewModel.state.description == "Test B")
    }

    @Test("State updates when price changes for target symbol")
    func stateUpdatesWhenPriceChangesForTargetSymbol() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[0]

        viewModel.configure(with: store, symbol: targetSymbol)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 200.0, change: 10.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.priceText == "$200.00")
        #expect(viewModel.state.isPositive == true)
        #expect(viewModel.state.changeArrow == "arrow.up")
    }

    @Test("State shows down arrow for negative change")
    func stateShowsDownArrowForNegativeChange() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[0]

        viewModel.configure(with: store, symbol: targetSymbol)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 80.0, change: -5.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.isPositive == false)
        #expect(viewModel.state.changeArrow == "arrow.down")
    }

    @Test("Flash is propagated to state")
    func flashIsPropagatedToState() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[0]

        viewModel.configure(with: store, symbol: targetSymbol)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 100.0, change: 5.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.flash == .up)
    }

    @Test("Updates to other symbols do not affect state")
    func updatesToOtherSymbolsDoNotAffectState() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[0]

        viewModel.configure(with: store, symbol: targetSymbol)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "BBB", price: 500.0, change: 50.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.symbol == "AAA")
        #expect(viewModel.state.priceText == "$--")
    }

    @Test("Configure selects symbol in store")
    func configureSelectsSymbolInStore() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = DetailViewModel()
        let targetSymbol = testSymbols[1]

        viewModel.configure(with: store, symbol: targetSymbol)

        #expect(store.state.selectedSymbol == targetSymbol)
    }
}
