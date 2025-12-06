import Combine
import Foundation
@testable import PriceTracker

final class MockWebSocketManager: WebSocketManaging {
    let updates = PassthroughSubject<PriceUpdate, Never>()
    let connectionStatus = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private(set) var lastConnectedSymbols: [StockSymbol] = []

    func connect(with symbols: [StockSymbol]) {
        connectCallCount += 1
        lastConnectedSymbols = symbols
        connectionStatus.send(.connecting)
    }

    func disconnect() {
        disconnectCallCount += 1
        connectionStatus.send(.disconnected)
    }

    func simulateConnected() {
        connectionStatus.send(.connected)
    }

    func simulateReconnecting(attempt: Int) {
        connectionStatus.send(.reconnecting(attempt: attempt))
    }

    func simulatePriceUpdate(_ update: PriceUpdate) {
        updates.send(update)
    }
}
