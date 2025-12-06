import XCTest
@testable import PriceTracker

@MainActor
final class PriceTrackerStoreTests: XCTestCase {
    func testApplyingPositiveUpdateSetsFlashUp() async throws {
        let manager = WebSocketManager()
        let store = PriceTrackerStore(
            webSocketManager: manager,
            symbols: [StockSymbol(symbol: "AAA", name: "Company A", description: "Test symbol")]
        )

        manager.updates.send(PriceUpdate(symbol: "AAA", price: 120, change: 1.5))
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(store.state.prices["AAA"]?.price, 120)
        XCTAssertEqual(store.state.flashes["AAA"], .up)
    }

    func testFlashClearsAfterDelay() async throws {
        let manager = WebSocketManager()
        let store = PriceTrackerStore(
            webSocketManager: manager,
            symbols: [StockSymbol(symbol: "AAA", name: "Company A", description: "Test symbol")]
        )

        manager.updates.send(PriceUpdate(symbol: "AAA", price: 90, change: -2.0))
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(store.state.flashes["AAA"], .down)

        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNil(store.state.flashes["AAA"])
    }
}
