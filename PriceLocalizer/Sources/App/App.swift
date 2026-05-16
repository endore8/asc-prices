import SwiftUI

@main
struct PriceLocalizerApp: App {
    private let appDependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1100, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}
