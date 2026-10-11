import SwiftUI

/// Regular dark Liquid Glass, matching React `GlassView`
/// (`glassEffectStyle="regular"`, `colorScheme="dark"`).
struct GlassSurface<Content: View>: View {
    var cornerRadius: CGFloat = Theme.radiusCard
    var tint: Color? = nil
    var interactive: Bool = false
    var padding: CGFloat = 0
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var glass: Glass {
        var value = Glass.regular
        if let tint { value = value.tint(tint) }
        if interactive { value = value.interactive() }
        return value
    }

    var body: some View {
        content()
            .padding(padding)
            .glassEffect(glass, in: shape)
            .overlay { shape.strokeBorder(Theme.hairline, lineWidth: 0.5) }
    }
}

struct GlassIconButton: View {
    var systemName: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
