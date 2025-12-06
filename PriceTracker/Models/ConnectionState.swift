import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected

    var isActive: Bool {
        switch self {
        case .connecting, .connected:
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
        }
    }
}
