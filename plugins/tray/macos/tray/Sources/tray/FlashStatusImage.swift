import AppKit

final class FlashStatusImage {
    static func make(country: String, status: String, isHighQuality: Bool = false) -> NSImage {
        let colors: [String: NSColor] = [
            "tun": .systemGreen, "route": .systemBlue, "entry": .systemOrange,
            "unknown": .systemGray, "stopped": .systemGray,
        ]
        let label = status == "failed" ? "F" :
            (country.range(of: "^[A-Z]{2}$", options: .regularExpression) != nil ? country : "--")
        let size = NSSize(width: 26, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let failed = status == "failed"
            let background = failed ? NSColor.systemGray.withAlphaComponent(0.18) :
                (colors[status] ?? .systemGray)
            background.setFill()
            outline(rect.insetBy(dx: 0, dy: 1)).fill()
            if status == "stopped" {
                drawLogo(in: rect)
                return true
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12.5, weight: .heavy),
                .foregroundColor: failed ? NSColor.systemRed : (isHighQuality ? NSColor.white : NSColor.black),
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

    private static func outline(_ rect: NSRect) -> NSBezierPath {
        let radius: CGFloat = 6
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + radius, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX - radius, y: rect.minY))
        path.curve(to: NSPoint(x: rect.maxX, y: rect.minY + radius),
                   controlPoint1: NSPoint(x: rect.maxX, y: rect.minY),
                   controlPoint2: NSPoint(x: rect.maxX, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - radius))
        path.curve(to: NSPoint(x: rect.maxX - radius, y: rect.maxY),
                   controlPoint1: NSPoint(x: rect.maxX, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.minX + radius, y: rect.maxY))
        path.curve(to: NSPoint(x: rect.minX, y: rect.maxY - radius),
                   controlPoint1: NSPoint(x: rect.minX, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.minX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.minX, y: rect.minY + radius))
        path.curve(to: NSPoint(x: rect.minX + radius, y: rect.minY),
                   controlPoint1: NSPoint(x: rect.minX, y: rect.minY),
                   controlPoint2: NSPoint(x: rect.minX, y: rect.minY))
        path.close()
        return path
    }

    private static func drawLogo(in rect: NSRect) {
        // Geometry shared with the upstream assets_source/images/icon/glyph.svg.
        let scale: CGFloat = 14 / 240
        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(x: rect.midX - 7 + x * scale, y: rect.midY + 7 - y * scale)
        }
        NSColor.white.setStroke()
        let bars = NSBezierPath()
        bars.lineWidth = 46.32 * scale
        bars.lineCapStyle = .round
        bars.move(to: point(59.68, 100.95))
        bars.line(to: point(180.02, 31.47))
        bars.move(to: point(90.56, 154.43))
        bars.line(to: point(150.74, 119.69))
        bars.stroke()
        NSColor.white.setFill()
        let center = point(121.44, 207.92)
        let radius = 23.16 * scale
        NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius,
                                   width: radius * 2, height: radius * 2)).fill()
    }
}
