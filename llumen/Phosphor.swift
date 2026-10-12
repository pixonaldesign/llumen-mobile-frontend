import SwiftUI
import UIKit

/// Phosphor regular, from the Phosphor icon font.
enum Phosphor: String {
    case pencilSimple = "\u{E3B4}"
    case funnel = "\u{E266}"
    case squaresFour = "\u{E464}"
    case fileText = "\u{E23A}"
    case user = "\u{E4C2}"
    case chatCircle = "\u{E168}"
    case dotsThree = "\u{E1FE}"
    case x = "\u{E4F6}"
    case list = "\u{E2F0}"
    case caretLeft = "\u{E138}"
    case caretRight = "\u{E13A}"
    case plus = "\u{E3D4}"
    case database = "\u{E1DE}"
    case presentation = "\u{E654}"
    case clipboardText = "\u{E198}"
    case images = "\u{E836}"
    case file = "\u{E230}"
    case paperclip = "\u{E39A}"
    case at = "\u{E0AC}"
    case magnifyingGlass = "\u{E30C}"
    case copy = "\u{E1CA}"
    case arrowUp = "\u{E08E}"
    case minus = "\u{E32A}"
    case square = "\u{E45E}"
    case rectangle = "\u{E3F0}"
    case check = "\u{E182}"
    case eye = "\u{E220}"
    case thumbsUp = "\u{E48E}"
    case thumbsDown = "\u{E48C}"
    case bookOpen = "\u{E0E6}"
    case info = "\u{E2CE}"
    case xCircle = "\u{E4F8}"
    case slideshow = "\u{ED32}"
    case microphone = "\u{E326}"
    case asterisk = "\u{E0AA}"

    /// Every icon draws its lines at this width in points, whatever its size.
    static let strokeWidth: CGFloat = 1.25

    var image: Image {
        Image(uiImage: PhosphorRaster.image(for: self, pointSize: 20, scale: 3))
    }
}

struct PhosphorIcon: View {
    var icon: Phosphor
    var size: CGFloat = 18
    @Environment(\.displayScale) private var displayScale

    init(_ icon: Phosphor, size: CGFloat = 18) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Image(uiImage: PhosphorRaster.image(for: icon, pointSize: size, scale: displayScale))
            .renderingMode(.template)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct PhosphorMenuLabel: View {
    var title: String
    var icon: Phosphor

    var body: some View {
        Label {
            Text(title)
        } icon: {
            icon.image
        }
    }
}

/// Draws glyph outlines into an em-square image, then grows or erodes them so the line width
/// matches `Phosphor.strokeWidth`. The font's own lines are 1/16 of the point size.
private enum PhosphorRaster {
    private static var cache: [String: UIImage] = [:]

    static func image(for icon: Phosphor, pointSize: CGFloat, scale: CGFloat) -> UIImage {
        let key = "\(icon.rawValue)-\(pointSize)-\(scale)"
        if let cached = cache[key] { return cached }

        let font = CTFontCreateWithName("Phosphor" as CFString, pointSize, nil)
        var characters = Array(icon.rawValue.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        CTFontGetGlyphsForCharacters(font, &characters, &glyphs, characters.count)
        var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: CTFontGetAscent(font))
        let path = CTFontCreatePathForGlyph(font, glyphs[0], &flip)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let canvas = CGSize(width: pointSize, height: pointSize)
        let adjust = Phosphor.strokeWidth - pointSize / 16

        let image = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            guard let path else { return }
            let cg = context.cgContext
            cg.setFillColor(UIColor.black.cgColor)
            cg.setStrokeColor(UIColor.black.cgColor)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)
            cg.addPath(path)
            cg.fillPath(using: .winding)
            guard abs(adjust) > 0.01 else { return }
            if adjust < 0 { cg.setBlendMode(.clear) }
            cg.setLineWidth(abs(adjust))
            cg.addPath(path)
            cg.strokePath()
        }.withRenderingMode(.alwaysTemplate)
        cache[key] = image
        return image
    }
}
