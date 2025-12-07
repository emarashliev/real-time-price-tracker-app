import Foundation

// MARK: - ConnectionState
// Represents WebSocket connection lifecycle states.
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)

    /// True if the connection is in progress or established (i.e., streaming is "on" from user's perspective).
    var isActive: Bool {
        switch self {
        case .connecting, .connected, .reconnecting:
            return true
        case .disconnected:
            return false
        }
    }

    var label: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Live"
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt)/\(Constants.maxReconnectAttempts))"
        }
    }
}
