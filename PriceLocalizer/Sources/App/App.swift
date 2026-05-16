import SwiftUI

@main
struct PriceLocalizerApp: App {
    private let appDependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}
