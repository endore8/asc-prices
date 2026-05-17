import SwiftUI

@main
struct PriceLocalizerApp: App {
    private let appDependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(self.appDependencies.authState)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
