import SwiftUI

/// Regular Liquid Glass. The material follows the system appearance:
/// dark glass while the system is dark, white glass when it is light.
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
    }
}

/// List-row plate using the same regular Liquid Glass as the cards.
struct GlassRowBackground: View {
    var body: some View {
        Color.clear
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
    }
}

struct GlassIconButton: View {
    var icon: Phosphor
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            PhosphorIcon(icon, size: 16)
                .foregroundStyle(Theme.text)
                .frame(width: 36, height: 36)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Blue liquid glass, fully rounded, for primary actions.
    func blueGlass() -> some View {
        glassEffect(.regular.tint(Theme.primary).interactive(), in: Capsule())
    }

    func blueGlassCircle() -> some View {
        glassEffect(.regular.tint(Theme.primary).interactive(), in: Circle())
    }
}
