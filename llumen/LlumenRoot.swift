import SwiftUI

struct LlumenRoot: View {
    @State private var model = AppModel()

    var body: some View {
        Group {
            if model.signedIn {
                AppShell()
            } else {
                SignInScreen()
            }
        }
        .environment(model)
        .font(LumenFont.font(14))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LlumenRoot()
}
