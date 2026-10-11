import SwiftUI

/// Night surface from the Lumen design system. Glass blurs this, not a brand wash.
struct LlumenBackground<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content()
        }
    }
}
