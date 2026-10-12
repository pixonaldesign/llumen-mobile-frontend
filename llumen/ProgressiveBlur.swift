import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// Backdrop blur whose radius ramps from zero at the top edge to `maxRadius` at the bottom edge.
struct ProgressiveBlur: UIViewRepresentable {
    var maxRadius: CGFloat = 12

    func makeUIView(context: Context) -> VariableBlurView {
        VariableBlurView(maxRadius: maxRadius)
    }

    func updateUIView(_ uiView: VariableBlurView, context: Context) {
        uiView.maxRadius = maxRadius
    }
}

final class VariableBlurView: UIVisualEffectView {
    var maxRadius: CGFloat {
        didSet {
            guard maxRadius != oldValue else { return }
            applyFilter()
        }
    }

    private static let mask: CGImage? = {
        let size: CGFloat = 100
        let gradient = CIFilter.smoothLinearGradient()
        // Core Image's origin is bottom-left: full blur at y = 0, none at the top.
        gradient.point0 = CGPoint(x: 0, y: 0)
        gradient.point1 = CGPoint(x: 0, y: size)
        gradient.color0 = .black
        gradient.color1 = .clear
        guard let output = gradient.outputImage else { return nil }
        return CIContext().createCGImage(output, from: CGRect(x: 0, y: 0, width: size, height: size))
    }()

    private var filter: NSObject?

    init(maxRadius: CGFloat) {
        self.maxRadius = maxRadius
        super.init(effect: UIBlurEffect(style: .regular))
        isUserInteractionEnabled = false
        applyFilter()
        // UIKit rebuilds the effect's layers on appearance changes, which drops the filter.
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitDisplayScale.self]) { (view: VariableBlurView, _) in
            DispatchQueue.main.async { view.ensureFilter() }
        }
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ensureFilter()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ensureFilter()
    }

    private func ensureFilter() {
        guard let backdrop = subviews.first?.layer else { return }
        let installed = (backdrop.filters?.first as AnyObject?) === filter
        if !installed || subviews.dropFirst().contains(where: { $0.alpha != 0 }) {
            applyFilter()
        }
    }

    private func applyFilter() {
        guard
            let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
            let filter = filterClass
                .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
                .takeUnretainedValue() as? NSObject
        else { return }
        filter.setValue(maxRadius, forKey: "inputRadius")
        filter.setValue(Self.mask, forKey: "inputMaskImage")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        self.filter = filter

        // The first subview is the backdrop; the rest are the material's tint and saturation layers.
        guard let backdrop = subviews.first?.layer else { return }
        backdrop.filters = [filter]
        if let window {
            backdrop.setValue(window.traitCollection.displayScale, forKey: "scale")
        }
        for view in subviews.dropFirst() {
            view.alpha = 0
        }
    }
}
