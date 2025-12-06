import Combine
import Foundation

struct DetailViewState: Equatable {
    let symbol: String
    let name: String
    let description: String
    let priceText: String
    let changeArrow: String
    let isPositive: Bool
    let flash: PriceFlash?
}

@MainActor
final class DetailViewModel: ObservableObject {
    @Published private(set) var state: DetailViewState = .init(
        symbol: "--",
        name: "--",
        description: "",
        priceText: "$--",
        changeArrow: "arrow.up",
        isPositive: true,
        flash: nil
    )

    private var store: PriceTrackerStore?
    private var targetSymbol: StockSymbol?
    private var cancellables: Set<AnyCancellable> = []

    func configure(with store: PriceTrackerStore, symbol: StockSymbol) {
        guard self.store == nil else { return }
        self.store = store
        self.targetSymbol = symbol
        store.select(symbol: symbol)
        state = DetailViewModel.makeState(from: store.state, targetSymbol: symbol)
        bind()
    }

    private func bind() {
        guard let store, let targetSymbol else { return }

        store.$state
            .map { appState in
                DetailViewModel.makeState(from: appState, targetSymbol: targetSymbol)
            }
            .removeDuplicates()
            .assign(to: &$state)
    }

    private static func makeState(from appState: AppState, targetSymbol: StockSymbol) -> DetailViewState {
        let update = appState.prices[targetSymbol.ticker]
        let priceText = update?.formattedPrice ?? "$--"
        let arrow = (update?.change ?? 0) >= 0 ? "arrow.up" : "arrow.down"
        let positive = (update?.change ?? 0) >= 0
        let flash = appState.flashes[targetSymbol.ticker]

        return DetailViewState(
            symbol: targetSymbol.ticker,
            name: targetSymbol.name,
            description: targetSymbol.description,
            priceText: priceText,
            changeArrow: arrow,
            isPositive: positive,
            flash: flash
        )
    }
}
