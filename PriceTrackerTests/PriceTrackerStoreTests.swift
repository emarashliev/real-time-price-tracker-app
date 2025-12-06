import Testing
@testable import PriceTracker

@MainActor
@Suite("PriceTrackerStore Tests")
struct PriceTrackerStoreTests {
    let testSymbols = [
        StockSymbol(symbol: "AAA", name: "Company A", description: "Test symbol A"),
        StockSymbol(symbol: "BBB", name: "Company B", description: "Test symbol B")
    ]

    @Test("Applying positive update sets flash up")
    func applyingPositiveUpdateSetsFlashUp() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 120, change: 1.5))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.state.prices["AAA"]?.price == 120)
        #expect(store.state.flashes["AAA"] == .up)
    }

    @Test("Applying negative update sets flash down")
    func applyingNegativeUpdateSetsFlashDown() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 90, change: -2.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.state.prices["AAA"]?.price == 90)
        #expect(store.state.flashes["AAA"] == .down)
    }

    @Test("Flash clears after delay")
    func flashClearsAfterDelay() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 90, change: -2.0))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(store.state.flashes["AAA"] == .down)

        try await Task.sleep(nanoseconds: 1_200_000_000)
        #expect(store.state.flashes["AAA"] == nil)
    }

    @Test("Start streaming calls connect on manager")
    func startStreamingCallsConnect() {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        store.startStreaming()

        #expect(manager.connectCallCount == 1)
        #expect(manager.lastConnectedSymbols.count == 2)
    }

    @Test("Stop streaming calls disconnect on manager")
    func stopStreamingCallsDisconnect() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        store.startStreaming()
        store.stopStreaming()

        #expect(manager.disconnectCallCount == 1)
    }

    @Test("Connection status updates state")
    func connectionStatusUpdatesState() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        #expect(store.state.connectionState == .disconnected)

        manager.simulateConnected()
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(store.state.connectionState == .connected)

        manager.simulateReconnecting(attempt: 1)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(store.state.connectionState == .reconnecting(attempt: 1))
    }

    @Test("Selecting symbol updates state")
    func selectingSymbolUpdatesState() {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        let symbolB = testSymbols[1]
        store.select(symbol: symbolB)

        #expect(store.state.selectedSymbol == symbolB)
    }

    @Test("Initial state has first symbol selected")
    func initialStateHasFirstSymbolSelected() {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        #expect(store.state.selectedSymbol == testSymbols.first)
    }

    @Test("Multiple rapid updates keep last price")
    func multipleRapidUpdatesKeepLastPrice() async throws {
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: testSymbols)

        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 100, change: 1.0))
        try await Task.sleep(nanoseconds: 50_000_000)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 99, change: -1.0))
        try await Task.sleep(nanoseconds: 50_000_000)
        manager.simulatePriceUpdate(PriceUpdate(symbol: "AAA", price: 101, change: 2.0))
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.state.prices["AAA"]?.price == 101)
        // Flash should be up since last update was positive
        #expect(store.state.flashes["AAA"] == .up)
    }
}
