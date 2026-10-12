import SwiftUI

/// Surface behind Liquid Glass. Dark stays the elevated gray; light is a cool muted gray.
struct LlumenBackground<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content()
        }
    }
}
