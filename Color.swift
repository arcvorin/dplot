import AppKit
import SwiftUI

extension NSColor {
    // Create from #RGB, #RRGGBB, or #AARRGGBB
    convenience init?(hexString: String) {
        let s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&int) else { return nil }

        switch s.count {
        case 3:
            let r = (int >> 8) & 0xF, g = (int >> 4) & 0xF, b = int & 0xF
            self.init(calibratedRed: CGFloat(r) / 15, green: CGFloat(g) / 15, blue: CGFloat(b) / 15, alpha: 1)
        case 6:
            let r = (int >> 16) & 0xFF, g = (int >> 8) & 0xFF, b = int & 0xFF
            self.init(calibratedRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
        case 8:
            let a = (int >> 24) & 0xFF, r = (int >> 16) & 0xFF, g = (int >> 8) & 0xFF, b = int & 0xFF
            self.init(calibratedRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        default:
            return nil
        }
    }

    func toHexRGB() -> String {
        let c = usingColorSpace(.deviceRGB) ?? self
        let r = max(0, min(255, Int(round(c.redComponent * 255))))
        let g = max(0, min(255, Int(round(c.greenComponent * 255))))
        let b = max(0, min(255, Int(round(c.blueComponent * 255))))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Color {
    init?(hexString: String) {
        guard let ns = NSColor(hexString: hexString) else { return nil }
        self = Color(nsColor: ns)
    }
}
