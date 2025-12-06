import SwiftUI

@main
struct PriceTrackerApp: App {
    @StateObject private var store = PriceTrackerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
