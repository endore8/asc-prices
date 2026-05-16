import SwiftUI

@main
struct PriceLocalizerApp: App {
    private let appDependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowStyle(.titleBar)
    }
}
