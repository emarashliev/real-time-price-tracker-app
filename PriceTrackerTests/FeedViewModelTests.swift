import Testing
@testable import PriceTracker

@MainActor
@Suite("FeedViewModel Tests")
struct FeedViewModelTests {
    let testSymbols = [
        StockSymbol(symbol: "AAA", name: "Company A", description: "Test A"),
        StockSymbol(symbol: "BBB", name: "Company B", description: "Test B")
    ]

    @Test("Initial state has empty rows")
    func initialStateHasEmptyRows() {
        let viewModel = FeedViewModel()

        #expect(viewModel.state.rows.isEmpty)
        #expect(viewModel.state.connectionState == .disconnected)
    }

    @Test("Configure populates rows from store")
    func configurePopulatesRowsFromStore() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.rows.count == 2)
    }

    @Test("Rows update when prices change")
    func rowsUpdateWhenPricesChange() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 150.0, change: 2.5))
        try await Task.sleep(nanoseconds: 100_000_000)

        let row = viewModel.state.rows.first { $0.id == "AAA" }
        #expect(row?.priceText == "$150.00")
        #expect(row?.isPositive == true)
    }

    @Test("Rows are sorted by price descending")
    func rowsAreSortedByPriceDescending() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 50.0, change: 1.0))
        manager.simulatePriceUpdate(PriceUpdate(symbol: "BBB", price: 100.0, change: 1.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.state.rows.first?.id == "BBB")
        #expect(viewModel.state.rows.last?.id == "AAA")
    }

    @Test("Toggle streaming starts when disconnected")
    func toggleStreamingStartsWhenDisconnected() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        viewModel.toggleStreaming()

        #expect(manager.connectCallCount == 1)
    }

    @Test("Toggle streaming stops when connected")
    func toggleStreamingStopsWhenConnected() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        viewModel.startStreaming()
        manager.simulateConnected()
        try await Task.sleep(nanoseconds: 100_000_000)

        viewModel.toggleStreaming()

        #expect(manager.disconnectCallCount == 1)
    }

    @Test("Flash is propagated to rows")
    func flashIsPropagatedToRows() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)
        let viewModel = FeedViewModel()

        viewModel.configure(with: store)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 100.0, change: 5.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        let row = viewModel.state.rows.first { $0.id == "AAA" }
        #expect(row?.flash == .up)
    }
}
