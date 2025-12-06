import Combine
import Foundation

protocol WebSocketManaging: AnyObject {
    var updates: PassthroughSubject<PriceUpdate, Never> { get }
    var connectionStatus: CurrentValueSubject<ConnectionState, Never> { get }

    func connect(with symbols: [StockSymbol])
    func disconnect()
}
