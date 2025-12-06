import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)

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
