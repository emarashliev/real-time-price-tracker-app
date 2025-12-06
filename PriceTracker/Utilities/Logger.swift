import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.PriceTracker"

    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let viewModel = Logger(subsystem: subsystem, category: "viewModel")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
