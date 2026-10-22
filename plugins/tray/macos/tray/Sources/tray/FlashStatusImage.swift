import AppKit

final class FlashStatusImage {
    static func make(country: String, status: String) -> NSImage {
        let colors: [String: NSColor] = [
            "route": .systemBlue, "entry": .systemOrange, "failed": .systemRed,
            "unknown": .systemGray, "stopped": .systemGray,
        ]
        let label = country.range(of: "^[A-Z]{2}$", options: .regularExpression) != nil ? country : "--"
        let size = NSSize(width: 26, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            (colors[status] ?? .systemGray).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0, dy: 1)).fill()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor.white,
            ]
            let text = label as NSString
            let measured = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: (rect.width - measured.width) / 2,
                                 y: (rect.height - measured.height) / 2), withAttributes: attributes)
            return true
        }
        image.isTemplate = false
        return image
    }
}
