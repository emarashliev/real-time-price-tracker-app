# Real-Time Price Tracker

A SwiftUI iOS application for monitoring live stock prices using WebSocket connections. Built with a clean, immutable state architecture and comprehensive test coverage.

## Features

- **Real-Time Price Streaming**: Live price updates via WebSocket every 2 seconds
- **Connection Management**: Automatic reconnection with exponential backoff (up to 5 attempts)
- **Price Flash Animations**: Visual feedback with green/red highlights for price changes
- **Deep Linking**: Navigate directly to stock details via `stocks://symbol/{ticker}` URL scheme
- **25 Demo Stocks**: AAPL, MSFT, GOOG, AMZN, NVDA, and more

## Screenshots

| Feed View | Detail View |
|-----------|-------------|
| Stock list with prices and connection status | Large price display with flash effects |

## Architecture

The app follows an **immutable state architecture** with unidirectional data flow using Combine:

```
WebSocketManager (Networking)
        ↓ Combine subjects
PriceTrackerStore (@MainActor ObservableObject)
        ↓ @Published state
ViewModels (FeedViewModel, DetailViewModel)
        ↓ transform AppState
Views (SwiftUI)
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **AppState** | Single immutable state struct. Mutations return new instances. |
| **PriceTrackerStore** | Central coordinator between WebSocket events and UI |
| **ViewModels** | Transform AppState into view-specific state structs |
| **WebSocketManager** | URLSessionWebSocketTask with heartbeat and reconnection |

### Data Flow

1. `WebSocketManager` receives price updates and publishes via Combine subjects
2. `PriceTrackerStore` subscribes to updates and creates new `AppState` instances
3. ViewModels observe `store.$state` and map to view-specific state
4. Views render state and send user actions back through the store

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 6.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/emarashliev/real-time-price-tracker-app.git
cd real-time-price-tracker-app
```

2. Open the project in Xcode:
```bash
open PriceTracker.xcodeproj
```

3. Build and run on a simulator or device.

## Build Commands

```bash
# Build the project
xcodebuild -project PriceTracker.xcodeproj \
  -scheme PriceTracker \
  -destination "platform=iOS Simulator,arch=arm64,OS=26.1,name=iPhone 17" \
  build

# Run all tests
xcodebuild -project PriceTracker.xcodeproj \
  -scheme PriceTracker \
  -destination "platform=iOS Simulator,arch=arm64,OS=26.1,name=iPhone 17" \
  clean test

# Run a specific test class
xcodebuild -project PriceTracker.xcodeproj \
  -scheme PriceTracker \
  -destination "platform=iOS Simulator,arch=arm64,OS=26.1,name=iPhone 17" \
  -only-testing:PriceTrackerTests/PriceTrackerStoreTests \
  test
```

## Testing

The project uses the **Swift Testing** framework with comprehensive coverage:

### Unit Tests (`PriceTrackerTests/`)

| Test File | Coverage |
|-----------|----------|
| `PriceTrackerStoreTests.swift` | Store state management, flash behavior, streaming |
| `AppStateTests.swift` | Immutable state mutations, lookup performance |
| `FeedViewModelTests.swift` | Row population, sorting, flash propagation |
| `DetailViewModelTests.swift` | Symbol state, price updates, arrow indicators |

### Snapshot Tests (`SnapshotTests/`)

Visual regression tests using the **SnapshotTesting** library:

- Feed view in all connection states
- Detail view state combinations
- Component-level testing

## Project Structure

```
PriceTracker/
├── Views/
│   ├── PriceTrackerApp.swift      # App entry point
│   ├── ContentView.swift          # Navigation root with deep linking
│   ├── FeedView.swift             # Stock list display
│   └── DetailView.swift           # Single stock detail
├── ViewModels/
│   ├── PriceTrackerStore.swift    # Central state + AppState struct
│   ├── FeedViewModel.swift        # Feed-specific state transform
│   └── DetailViewModel.swift      # Detail-specific state transform
├── Models/
│   ├── StockSymbol.swift          # Stock definition + demo data
│   ├── PriceUpdate.swift          # Price data with calculations
│   └── ConnectionState.swift      # Connection lifecycle states
├── Networking/
│   ├── WebSocketManaging.swift    # Protocol definition
│   └── WebSocketManager.swift     # URLSessionWebSocketTask impl
└── Utilities/
    ├── Constants.swift            # Timing and configuration
    ├── Logger.swift               # OSLog-based logging
    └── PriceFlash+Color.swift     # Flash effect colors
```

## Deep Linking

The app supports the `stocks://` URL scheme for direct navigation:

```
stocks://symbol/AAPL    # Opens Apple detail view
stocks://symbol/MSFT    # Opens Microsoft detail view
stocks://symbol/GOOG    # Opens Google detail view
```

### Testing Deep Links

From Terminal:
```bash
xcrun simctl openurl booted "stocks://symbol/AAPL"
```

## Configuration

Key timing values in `Constants.swift`:

| Constant | Value | Description |
|----------|-------|-------------|
| `priceUpdateInterval` | 2s | Time between price updates |
| `heartbeatInterval` | 15s | WebSocket keepalive ping |
| `flashDuration` | 1s | Price flash visibility |
| `maxReconnectAttempts` | 5 | Reconnection retry limit |
| `flashOpacity` | 0.2 | Flash background intensity |

## WebSocket Server

The app connects to `wss://ws.postman-echo.com/raw` (Postman echo server) for demonstration. In production, replace with your stock data provider in `WebSocketManager.swift`.

## Logging

OSLog-based logging with categories:

```swift
Logger.networking  // WebSocket events
Logger.viewModel   // State changes
Logger.ui          // User interactions
```

View logs in Console.app by filtering for "PriceTracker".

## License

This project is available under the MIT License.
