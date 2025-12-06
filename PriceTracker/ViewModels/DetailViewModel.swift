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
    private var cancellables: Set<AnyCancellable> = []

    func configure(with store: PriceTrackerStore) {
        guard self.store == nil else { return }
        self.store = store
        state = DetailViewModel.makeState(from: store.state)
        bind()
    }

    private func bind() {
        guard let store else { return }

        store.$state
            .map(DetailViewModel.makeState)
            .removeDuplicates()
            .assign(to: &$state)
    }

    private static func makeState(from appState: AppState) -> DetailViewState {
        let symbol = appState.selectedSymbol ?? appState.symbols.first!
        let update = appState.prices[symbol.ticker]
        let priceText = update?.formattedPrice ?? "$--"
        let arrow = (update?.change ?? 0) >= 0 ? "arrow.up" : "arrow.down"
        let positive = (update?.change ?? 0) >= 0
        let flash = appState.flashes[symbol.ticker]

        return DetailViewState(
            symbol: symbol.ticker,
            name: symbol.name,
            description: symbol.description,
            priceText: priceText,
            changeArrow: arrow,
            isPositive: positive,
            flash: flash
        )
    }
}
