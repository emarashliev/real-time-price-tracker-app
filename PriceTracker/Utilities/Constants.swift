import Foundation

enum Constants {
    // MARK: - Timing
    static let priceUpdateInterval: UInt64 = 2_000_000_000  // 2 seconds
    static let heartbeatInterval: UInt64 = 15_000_000_000   // 15 seconds
    static let flashDuration: UInt64 = 1_000_000_000        // 1 second

    // MARK: - Reconnection
    static let initialReconnectDelay: TimeInterval = 1.0    // 1 second
    static let maxReconnectDelay: TimeInterval = 30.0       // 30 seconds
    static let maxReconnectAttempts: Int = 5

    // MARK: - UI
    static let flashOpacity: Double = 0.2
}
