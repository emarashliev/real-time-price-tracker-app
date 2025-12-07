import SwiftUI
import SnapshotTesting
import Testing
@testable import PriceTracker

@MainActor
@Suite("Component Snapshot Tests")
struct ComponentSnapshotTests {

    init() throws {
        try SnapshotDeviceRequirement.validate()
    }

    // MARK: - StatusBar Component Tests

    @Test("StatusBar connected state")
    func statusBarConnected() {
        let statusBar = StatusBarView(connectionState: .connected)

        assertSnapshot(
            of: statusBar.toViewController(size: CGSize(width: 150, height: 30)),
            as: .image
        )
    }

    @Test("StatusBar connecting state")
    func statusBarConnecting() {
        let statusBar = StatusBarView(connectionState: .connecting)

        assertSnapshot(
            of: statusBar.toViewController(size: CGSize(width: 150, height: 30)),
            as: .image
        )
    }

    @Test("StatusBar disconnected state")
    func statusBarDisconnected() {
        let statusBar = StatusBarView(connectionState: .disconnected)

        assertSnapshot(
            of: statusBar.toViewController(size: CGSize(width: 170, height: 30)),
            as: .image
        )
    }

    @Test("StatusBar reconnecting state")
    func statusBarReconnecting() {
        let statusBar = StatusBarView(connectionState: .reconnecting(attempt: 3))

        assertSnapshot(
            of: statusBar.toViewController(size: CGSize(width: 200, height: 30)),
            as: .image
        )
    }

    // MARK: - Control Button Tests

    @Test("Control button start state")
    func controlButtonStart() {
        let button = ControlButtonView(isStreaming: false, action: {})

        assertSnapshot(
            of: button.toViewController(size: CGSize(width: 100, height: 44)),
            as: .image
        )
    }

    @Test("Control button stop state")
    func controlButtonStop() {
        let button = ControlButtonView(isStreaming: true, action: {})

        assertSnapshot(
            of: button.toViewController(size: CGSize(width: 100, height: 44)),
            as: .image
        )
    }

    // MARK: - FeedRow Component Tests

    @Test("FeedRow positive price no flash")
    func feedRowPositiveNoFlash() {
        let row = FeedRowView(
            ticker: "AAPL",
            name: "Apple",
            priceText: "$192.34",
            changeText: "+1.12",
            isPositive: true,
            flash: nil
        )

        assertSnapshot(
            of: row.toViewController(size: CGSize(width: 375, height: 70)),
            as: .image
        )
    }

    @Test("FeedRow negative price no flash")
    func feedRowNegativeNoFlash() {
        let row = FeedRowView(
            ticker: "MSFT",
            name: "Microsoft",
            priceText: "$350.44",
            changeText: "-2.13",
            isPositive: false,
            flash: nil
        )

        assertSnapshot(
            of: row.toViewController(size: CGSize(width: 375, height: 70)),
            as: .image
        )
    }

    @Test("FeedRow with flash up")
    func feedRowFlashUp() {
        let row = FeedRowView(
            ticker: "AAPL",
            name: "Apple",
            priceText: "$195.00",
            changeText: "+2.66",
            isPositive: true,
            flash: .up
        )

        assertSnapshot(
            of: row.toViewController(size: CGSize(width: 375, height: 70)),
            as: .image
        )
    }

    @Test("FeedRow with flash down")
    func feedRowFlashDown() {
        let row = FeedRowView(
            ticker: "MSFT",
            name: "Microsoft",
            priceText: "$345.00",
            changeText: "-5.44",
            isPositive: false,
            flash: .down
        )

        assertSnapshot(
            of: row.toViewController(size: CGSize(width: 375, height: 70)),
            as: .image
        )
    }

    @Test("FeedRow dark mode")
    func feedRowDarkMode() {
        let row = FeedRowView(
            ticker: "AAPL",
            name: "Apple",
            priceText: "$192.34",
            changeText: "+1.12",
            isPositive: true,
            flash: nil
        )

        let vc = row.toViewController(size: CGSize(width: 375, height: 70))
        vc.overrideUserInterfaceStyle = .dark

        assertSnapshot(
            of: vc,
            as: .image
        )
    }
}

// MARK: - Extracted Component Views for Isolated Testing

/// Standalone StatusBar view for isolated testing
/// Mirrors the statusBar computed property in FeedView
private struct StatusBarView: View {
    let connectionState: ConnectionState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color(for: connectionState))
                .frame(width: 10, height: 10)
            Text(connectionState.label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .background(Color(.systemBackground))
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
}

/// Standalone Control Button view for isolated testing
/// Mirrors the controls computed property in FeedView
private struct ControlButtonView: View {
    let isStreaming: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isStreaming ? "Stop" : "Start", systemImage: isStreaming ? "stop.fill" : "play.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(isStreaming ? .red : .blue)
        .background(Color(.systemBackground))
    }
}

/// Standalone FeedRow view for isolated testing
/// Mirrors the row layout in FeedView's List
private struct FeedRowView: View {
    let ticker: String
    let name: String
    let priceText: String
    let changeText: String
    let isPositive: Bool
    let flash: PriceFlash?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ticker)
                    .font(.headline)
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(priceText)
                    .font(.headline)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(PriceFlash.backgroundColor(for: flash))
                    .cornerRadius(8)
                Text(changeText)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .foregroundColor(isPositive ? .green : .red)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
