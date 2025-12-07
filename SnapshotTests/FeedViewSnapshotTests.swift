import SwiftUI
import SnapshotTesting
import Testing
@testable import PriceTracker

@MainActor
@Suite("FeedView Snapshot Tests")
struct FeedViewSnapshotTests {

    init() throws {
        try SnapshotDeviceRequirement.validate()
    }

    // MARK: - Connection States

    @Test("FeedView connected state with prices")
    func feedViewConnectedState() {
        let store = SnapshotTestStore.connected()
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("FeedView disconnected state")
    func feedViewDisconnectedState() {
        let store = SnapshotTestStore.disconnected()
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("FeedView connecting state")
    func feedViewConnectingState() {
        let store = SnapshotTestStore.connecting()
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("FeedView reconnecting state")
    func feedViewReconnectingState() {
        let store = SnapshotTestStore.reconnecting(attempt: 2)
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    // MARK: - Flash States

    @Test("FeedView with flash up animation")
    func feedViewWithFlashUp() {
        let store = SnapshotTestStore.withFlashUp(on: "AAPL")
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    @Test("FeedView with flash down animation")
    func feedViewWithFlashDown() {
        let store = SnapshotTestStore.withFlashDown(on: "MSFT")
        let view = NavigationStack {
            FeedView()
                .environmentObject(store)
        }

        assertSnapshot(
            of: view.toViewController(),
            as: .image(on: .iPhone13Pro)
        )
    }

    // MARK: - Dark Mode

    @Test("FeedView dark mode")
    func feedViewDarkMode() {
        let store = SnapshotTestStore.connected()
        let view = NavigationStack {
            FeedView()
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
