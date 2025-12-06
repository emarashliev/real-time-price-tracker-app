import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PriceTrackerStore
    @State private var path: [StockSymbol] = []

    var body: some View {
        NavigationStack(path: $path) {
            FeedView()
                .navigationDestination(for: StockSymbol.self) { symbol in
                    DetailView(symbol: symbol)
                }
        }
        .onOpenURL(perform: handleDeepLink)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "stocks",
              url.host?.lowercased() == "symbol" else { return }

        let ticker = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !ticker.isEmpty else { return }

        if let symbol = store.state.symbols.first(where: { $0.ticker.caseInsensitiveCompare(ticker) == .orderedSame }) {
            store.select(symbol: symbol)
            path = [symbol]
        }
    }
}
