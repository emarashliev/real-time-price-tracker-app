import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var store: PriceTrackerStore
    @StateObject private var viewModel = DetailViewModel()
    private let symbol: StockSymbol

    init(symbol: StockSymbol) {
        self.symbol = symbol
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(viewModel.state.name)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: viewModel.state.changeArrow)
                        .foregroundColor(viewModel.state.isPositive ? .green : .red)
                    Text(viewModel.state.priceText)
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(PriceFlash.backgroundColor(for: viewModel.state.flash))
                        .cornerRadius(10)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.state.flash)
                }
            }

            Text(viewModel.state.description)
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle(viewModel.state.symbol)
        .onAppear {
            viewModel.configure(with: store, symbol: symbol)
        }
    }
}
