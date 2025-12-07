import Combine
import Foundation

// MARK: - FeedRow
// View-specific model for a single row in the price feed list.
struct FeedRow: Identifiable, Equatable {
    let id: String
    let name: String
    let priceText: String
    let changeText: String
    let isPositive: Bool
    let priceValue: Double
    let flash: PriceFlash?
}

struct FeedViewState: Equatable {
    let rows: [FeedRow]
    let connectionState: ConnectionState
}

// MARK: - FeedViewModel
// Transforms global AppState into FeedViewState for the feed list view.
// Subscribes to store state changes and maps to view-specific data.
@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var state: FeedViewState = .init(
        rows: [],
        connectionState: .disconnected
    )

    private var store: PriceTrackerStore?
    private var cancellables: Set<AnyCancellable> = []

    func startStreaming() {
        store?.startStreaming()
    }

    func stopStreaming() {
        store?.stopStreaming()
    }

    func select(symbol: StockSymbol) {
        store?.select(symbol: symbol)
    }

    func toggleStreaming() {
        if state.connectionState.isActive {
            stopStreaming()
        } else {
            startStreaming()
        }
    }

    // One-time configuration to bind to the store. Guard prevents re-binding
    // if the view appears multiple times during navigation.
    func configure(with store: PriceTrackerStore) {
        guard self.store == nil else { return }
        self.store = store
        state = FeedViewModel.makeState(from: store.state)
        bind()
    }

    private func bind() {
        guard let store else { return }

        store.$state
            .map(FeedViewModel.makeState)
            .removeDuplicates()
            .assign(to: &$state)
    }

    private static func makeState(from appState: AppState) -> FeedViewState {
        let rows: [FeedRow] = appState.symbols
            .map { symbol in
                let update = appState.prices[symbol.ticker]
                let priceValue = update?.price ?? 0
                let price = update?.formattedPrice ?? "$--"
                let change = update?.formattedChange ?? "--"
                let positive = (update?.change ?? 0) >= 0
                let flash = appState.flashes[symbol.ticker]
                return FeedRow(
                    id: symbol.ticker,
                    name: symbol.name,
                    priceText: price,
                    changeText: change,
                    isPositive: positive,
                    priceValue: priceValue,
                    flash: flash
                )
            }
            .sorted { lhs, rhs in lhs.priceValue > rhs.priceValue }  // Highest price first

        return FeedViewState(rows: rows, connectionState: appState.connectionState)
    }
}
