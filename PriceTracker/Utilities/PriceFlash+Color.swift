import SwiftUI

extension PriceFlash {
    var backgroundColor: Color {
        switch self {
        case .up:
            return Color.green.opacity(Constants.flashOpacity)
        case .down:
            return Color.red.opacity(Constants.flashOpacity)
        }
    }

    static func backgroundColor(for flash: PriceFlash?) -> Color {
        flash?.backgroundColor ?? .clear
    }
}
