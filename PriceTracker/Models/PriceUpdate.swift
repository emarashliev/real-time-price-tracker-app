import Foundation

enum PriceFlash: Equatable {
    case up
    case down
}

struct PriceUpdate: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let price: Double
    let change: Double

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    var formattedChange: String {
        let prefix = change >= 0 ? "+" : ""
        return String(format: "%@%.2f", prefix, change)
    }
}
