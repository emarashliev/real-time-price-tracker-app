import SwiftUI
import UIKit
import Combine
@testable import PriceTracker

// MARK: - Mock WebSocket Manager

final class MockWebSocketManager: WebSocketManaging {
    let updates = PassthroughSubject<PriceUpdate, Never>()
    let connectionStatus = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    func connect(with symbols: [StockSymbol]) {
        connectionStatus.send(.connecting)
    }

    func disconnect() {
        connectionStatus.send(.disconnected)
    }
}

// MARK: - Simulator Validation

enum SnapshotDeviceRequirement {
    static let expectedDeviceName = "iPhone 17"
    static let expectedOSVersion = "26.1"

    /// Validates that tests are running on the expected simulator.
    /// Call this at the start of snapshot tests to ensure consistency.
    static func validate() throws {
        #if targetEnvironment(simulator)
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Unknown"
        let osVersion = UIDevice.current.systemVersion

        // Handle Xcode's "Clone X of DeviceName" naming for parallel test runs
        guard isMatchingDevice(deviceName) else {
            throw SnapshotDeviceError.wrongDevice(
                actual: deviceName,
                expected: expectedDeviceName
            )
        }

        guard osVersion == expectedOSVersion else {
            throw SnapshotDeviceError.wrongOSVersion(
                actual: osVersion,
                expected: expectedOSVersion
            )
        }
        #else
        throw SnapshotDeviceError.notSimulator
        #endif
    }

    /// Checks if the device name matches, accounting for Xcode's clone naming
    private static func isMatchingDevice(_ deviceName: String) -> Bool {
        // Direct match
        if deviceName == expectedDeviceName {
            return true
        }
        // Match "Clone X of iPhone 17" pattern for parallel test execution
        if deviceName.hasSuffix(expectedDeviceName) && deviceName.hasPrefix("Clone") {
            return true
        }
        return false
    }

    /// Returns true if running on the expected simulator, false otherwise.
    static var isValidDevice: Bool {
        #if targetEnvironment(simulator)
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Unknown"
        let osVersion = UIDevice.current.systemVersion
        return isMatchingDevice(deviceName) && osVersion == expectedOSVersion
        #else
        return false
        #endif
    }

    /// Returns a description of the current device for debugging.
    static var currentDeviceDescription: String {
        #if targetEnvironment(simulator)
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Unknown"
        let osVersion = UIDevice.current.systemVersion
        return "\(deviceName) (iOS \(osVersion))"
        #else
        return "Physical device (not simulator)"
        #endif
    }
}

enum SnapshotDeviceError: Error, CustomStringConvertible {
    case wrongDevice(actual: String, expected: String)
    case wrongOSVersion(actual: String, expected: String)
    case notSimulator

    var description: String {
        switch self {
        case .wrongDevice(let actual, let expected):
            return "Snapshot tests must run on \(expected), but running on \(actual)"
        case .wrongOSVersion(let actual, let expected):
            return "Snapshot tests must run on iOS \(expected), but running on iOS \(actual)"
        case .notSimulator:
            return "Snapshot tests must run on a simulator, not a physical device"
        }
    }
}

// MARK: - SwiftUI View to UIViewController Wrapper

extension SwiftUI.View {
    /// Wraps SwiftUI view in UIHostingController for snapshot testing
    func toViewController(size: CGSize? = nil) -> UIViewController {
        let hostingController = UIHostingController(rootView: self)

        // Prefer an explicit size for deterministic snapshots.
        // If none is provided, fall back to a common iPhone logical size (e.g., 390x844).
        let targetSize = size ?? CGSize(width: 390, height: 844)

        hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .systemBackground
        return hostingController
    }
}

// MARK: - Test Store Factory

enum SnapshotTestStore {
    /// Creates a store with connected state and sample prices
    @MainActor
    static func connected() -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let samplePrices: [String: PriceUpdate] = [
            "AAPL": PriceUpdate(symbol: "AAPL", price: 192.34, change: 1.12),
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
        return store
    }

    /// Creates a store with disconnected state
    @MainActor
    static func disconnected() -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)
        let state = AppState(
            symbols: symbols,
            prices: [:],
            connectionState: .disconnected,
            selectedSymbol: symbols.first,
            flashes: [:]
        )
        
        store.setState(state)
        return store
    }

    /// Creates a store with connecting state
    @MainActor
    static func connecting() -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let state = AppState(
            symbols: symbols,
            prices: [:],
            connectionState: .connecting,
            selectedSymbol: symbols.first,
            flashes: [:]
        )
        
        store.setState(state)
        return store
    }

    /// Creates a store with reconnecting state
    @MainActor
    static func reconnecting(attempt: Int = 2) -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let state = AppState(
            symbols: symbols,
            prices: [:],
            connectionState: .reconnecting(attempt: attempt),
            selectedSymbol: symbols.first,
            flashes: [:]
        )
        store.setState(state)
        return store
    }

    /// Creates a store with flash up on a specific symbol
    @MainActor
    static func withFlashUp(on ticker: String = "AAPL") -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let samplePrices: [String: PriceUpdate] = [
            "AAPL": PriceUpdate(symbol: "AAPL", price: 195.00, change: 2.66),
            "MSFT": PriceUpdate(symbol: "MSFT", price: 350.44, change: -2.13),
            "GOOG": PriceUpdate(symbol: "GOOG", price: 140.02, change: 0.45)
        ]

        let state = AppState(
            symbols: symbols,
            prices: samplePrices,
            connectionState: .connected,
            selectedSymbol: symbols.first,
            flashes: [ticker: .up]
        )
        
        store.setState(state)
        return store
    }

    /// Creates a store with flash down on a specific symbol
    @MainActor
    static func withFlashDown(on ticker: String = "MSFT") -> PriceTrackerStore {
        let symbols = Array(StockSymbol.demoSymbols.prefix(3))
        let manager = MockWebSocketManager()
        let store = PriceTrackerStore(webSocketManager: manager, symbols: symbols)

        let samplePrices: [String: PriceUpdate] = [
            "AAPL": PriceUpdate(symbol: "AAPL", price: 192.34, change: 1.12),
            "MSFT": PriceUpdate(symbol: "MSFT", price: 345.00, change: -5.44),
            "GOOG": PriceUpdate(symbol: "GOOG", price: 140.02, change: 0.45)
        ]

        let state = AppState(
            symbols: symbols,
            prices: samplePrices,
            connectionState: .connected,
            selectedSymbol: symbols.first,
            flashes: [ticker: .down]
        )
        
        store.setState(state)
        return store
    }
}
