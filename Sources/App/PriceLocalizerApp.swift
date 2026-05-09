import SwiftUI

@main
struct PriceLocalizerApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .frame(minWidth: 1100, minHeight: 640)
        }
        .windowStyle(.titleBar)
    }
}
