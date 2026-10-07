import SwiftUI

@main struct MyApp: App {
    init() {
        LumenFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
