import SwiftUI

@main struct LlumenApp: App {
    init() {
        LumenFont.register()
        AuroraStage.preload()
    }

    var body: some Scene {
        WindowGroup {
            LlumenRoot()
        }
    }
}
