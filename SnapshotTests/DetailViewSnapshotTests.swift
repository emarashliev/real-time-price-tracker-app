import SwiftUI
import SnapshotTesting
import Testing
@testable import PriceTracker

@MainActor
@Suite("DetailView Snapshot Tests")
struct DetailViewSnapshotTests {

    init() throws {
        try SnapshotDeviceRequirement.validate()
    }

    // MARK: - Price Change States

    @Test("DetailView positive price change")
    func detailViewPositiveChange() {
        let store = SnapshotTestStore.connected()
        let symbol = store.state.symbols.first!

        let view = NavigationStack {
            DetailView(symbol: symbol)
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("DetailView negative price change")
    func detailViewNegativeChange() {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let samplePrices: [String: PriceUpdate] = [
            "AAPL": PriceUpdate(symbol: "AAPL", price: 188.22, change: -4.12),
            "MSFT": PriceUpdate(symbol: "MSFT", price: 350.44, change: -2.13),
            "GOOG": PriceUpdate(symbol: "GOOG", price: 140.02, change: 0.45)
        ]

        let state = AppState(
            symbols: symbols,
            prices: samplePrices,
            connectionState: .connected,
            selectedSymbol: symbols.first,
            flashes: [:]
        )

        store.setState(state)

        let view = NavigationStack {
            DetailView(symbol: symbols.first!)
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    // MARK: - Flash States

    @Test("DetailView with flash up")
    func detailViewFlashUp() {
        let store = SnapshotTestStore.withFlashUp(on: "AAPL")
        let symbol = store.state.symbols.first!

        let view = NavigationStack {
            DetailView(symbol: symbol)
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("DetailView with flash down")
    func detailViewFlashDown() {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let samplePrices: [String: PriceUpdate] = [
            "AAPL": PriceUpdate(symbol: "AAPL", price: 185.00, change: -7.34),
            "MSFT": PriceUpdate(symbol: "MSFT", price: 350.44, change: -2.13),
            "GOOG": PriceUpdate(symbol: "GOOG", price: 140.02, change: 0.45)
        ]

        let state = AppState(
            symbols: symbols,
            prices: samplePrices,
            connectionState: .connected,
            selectedSymbol: symbols.first,
            flashes: ["AAPL": .down]
        )
        
        store.setState(state)

        let view = NavigationStack {
            DetailView(symbol: symbols.first!)
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    // MARK: - Initial State

    @Test("DetailView no price data (initial state)")
    func detailViewNoPriceData() {
        let store = SnapshotTestStore.disconnected()
        let symbol = store.state.symbols.first!

        let view = NavigationStack {
            DetailView(symbol: symbol)
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    // MARK: - Dark Mode

    @Test("DetailView dark mode")
    func detailViewDarkMode() {
        let store = SnapshotTestStore.connected()
        let symbol = store.state.symbols.first!

        let view = NavigationStack {
            DetailView(symbol: symbol)
                .environmentObject(store)
        }

        let vc = view.toViewController()
        vc.overrideUserInterfaceStyle = .dark

        assertSnapshot(
            of: vc,
            as: .image(on: .iPhone13Pro)
        )
    }
}
