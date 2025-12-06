import Testing
@testable import PriceTracker

@Suite("AppState Tests")
struct AppStateTests {
    let testSymbols = [
        StockSymbol(symbol: "AAA", name: "Company A", description: "Test A"),
        StockSymbol(symbol: "BBB", name: "Company B", description: "Test B")
    ]

    @Test("Initial state has correct defaults")
    func initialStateHasCorrectDefaults() {
        let state = AppState(symbols: testSymbols)

        #expect(state.symbols.count == 2)
        #expect(state.prices.isEmpty)
        #expect(state.connectionState == .disconnected)
        #expect(state.selectedSymbol == nil)
        #expect(state.flashes.isEmpty)
    }

    @Test("SymbolsByTicker provides O(1) lookup")
    func symbolsByTickerProvidesLookup() {
        let state = AppState(symbols: testSymbols)

        #expect(state.symbol(for: "AAA")?.name == "Company A")
        #expect(state.symbol(for: "BBB")?.name == "Company B")
        #expect(state.symbol(for: "CCC") == nil)
    }

    @Test("Updating connection returns new state")
    func updatingConnectionReturnsNewState() {
        let state = AppState(symbols: testSymbols)
        let newState = state.updatingConnection(.connected)

        #expect(newState.connectionState == .connected)
        #expect(state.connectionState == .disconnected)
    }

    @Test("Applying update adds price and flash")
    func applyingUpdateAddsPriceAndFlash() {
        let state = AppState(symbols: testSymbols)
        let update = PriceUpdate(symbol: "AAA", price: 100.0, change: 5.0)
        let newState = state.applying(update)

        #expect(newState.prices["AAA"]?.price == 100.0)
        #expect(newState.flashes["AAA"] == .up)
    }

    @Test("Applying negative update sets flash down")
    func applyingNegativeUpdateSetsFlashDown() {
        let state = AppState(symbols: testSymbols)
        let update = PriceUpdate(symbol: "AAA", price: 100.0, change: -5.0)
        let newState = state.applying(update)

        #expect(newState.flashes["AAA"] == .down)
    }

    @Test("Applying zero change does not set flash")
    func applyingZeroChangeDoesNotSetFlash() {
        let state = AppState(symbols: testSymbols)
        let update = PriceUpdate(symbol: "AAA", price: 100.0, change: 0.0)
        let newState = state.applying(update)

        #expect(newState.prices["AAA"]?.price == 100.0)
        #expect(newState.flashes["AAA"] == nil)
    }

    @Test("Selecting symbol returns new state")
    func selectingSymbolReturnsNewState() {
        let state = AppState(symbols: testSymbols)
        let symbol = testSymbols[1]
        let newState = state.selecting(symbol)

        #expect(newState.selectedSymbol == symbol)
        #expect(state.selectedSymbol == nil)
    }

    @Test("Clearing flash removes flash for symbol")
    func clearingFlashRemovesFlashForSymbol() {
        let state = AppState(symbols: testSymbols, flashes: ["AAA": .up, "BBB": .down])
        let newState = state.clearingFlash(for: "AAA")

        #expect(newState.flashes["AAA"] == nil)
        #expect(newState.flashes["BBB"] == .down)
    }

    @Test("Reconnecting state shows correct label")
    func reconnectingStateShowsCorrectLabel() {
        let state = ConnectionState.reconnecting(attempt: 2)
        #expect(state.label == "Reconnecting (2/5)")
        #expect(state.isActive == true)
    }
}
