import Foundation

struct StockSymbol: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String

    init(symbol: String, name: String, description: String = "") {
        self.id = symbol
        self.name = name
        self.description = description.isEmpty ? "Real-time updates for \(name)." : description
    }

    var ticker: String { id }
}

extension StockSymbol {
    static let demoSymbols: [StockSymbol] = [
        StockSymbol(symbol: "AAPL", name: "Apple"),
        StockSymbol(symbol: "MSFT", name: "Microsoft"),
        StockSymbol(symbol: "GOOG", name: "Alphabet"),
        StockSymbol(symbol: "AMZN", name: "Amazon"),
        StockSymbol(symbol: "META", name: "Meta"),
        StockSymbol(symbol: "NVDA", name: "Nvidia"),
        StockSymbol(symbol: "TSLA", name: "Tesla"),
        StockSymbol(symbol: "NFLX", name: "Netflix"),
        StockSymbol(symbol: "CRM", name: "Salesforce"),
        StockSymbol(symbol: "ORCL", name: "Oracle"),
        StockSymbol(symbol: "ADBE", name: "Adobe"),
        StockSymbol(symbol: "INTC", name: "Intel"),
        StockSymbol(symbol: "AMD", name: "AMD"),
        StockSymbol(symbol: "IBM", name: "IBM"),
        StockSymbol(symbol: "UBER", name: "Uber"),
        StockSymbol(symbol: "LYFT", name: "Lyft"),
        StockSymbol(symbol: "SHOP", name: "Shopify"),
        StockSymbol(symbol: "SQ", name: "Block"),
        StockSymbol(symbol: "TWTR", name: "Twitter"),
        StockSymbol(symbol: "SNAP", name: "Snap"),
        StockSymbol(symbol: "PINS", name: "Pinterest"),
        StockSymbol(symbol: "BABA", name: "Alibaba"),
        StockSymbol(symbol: "JD", name: "JD.com"),
        StockSymbol(symbol: "SONY", name: "Sony"),
        StockSymbol(symbol: "SPOT", name: "Spotify")
    ]
}
