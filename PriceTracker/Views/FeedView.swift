import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var store: PriceTrackerStore
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusBar
            controls
            List(viewModel.state.rows) { row in
                if let symbol = store.state.symbol(for: row.id) {
                    NavigationLink(value: symbol) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(row.id)
                                    .font(.headline)
                                Text(row.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(row.priceText)
                                    .font(.headline)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(PriceFlash.backgroundColor(for: row.flash))
                                    .cornerRadius(8)
                                    .animation(.easeInOut(duration: 0.2), value: row.flash)
                                Text(row.changeText)
                                    .font(.caption)
                                    .foregroundColor(row.isPositive ? .green : .red)
                            }
                            Image(systemName: row.isPositive ? "arrow.up" : "arrow.down")
                                .foregroundColor(row.isPositive ? .green : .red)
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.select(symbol: symbol)
                    })
                }
            }
            .listStyle(.plain)
        }
        .padding()
        .navigationTitle("Live Prices")
        .onAppear {
            viewModel.configure(with: store)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: viewModel.state.connectionState))
                .frame(width: 10, height: 10)
            Text(viewModel.state.connectionState.label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var controls: some View {
        Button(action: viewModel.toggleStreaming) {
            Label(isStreaming ? "Stop" : "Start", systemImage: isStreaming ? "stop.fill" : "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(isStreaming ? .red : .blue)
    }

    private func color(for state: ConnectionState) -> Color {
        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        }
    }

    private var isStreaming: Bool {
        viewModel.state.connectionState.isActive
    }
}
