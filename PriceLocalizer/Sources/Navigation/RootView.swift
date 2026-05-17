import SwiftUI

struct RootView: View {
    @Environment(AuthState.self) private var authState

    @State private var ascClient: ASCClient?

    var body: some View {
        Group {
            if let ascClient {
                MainPage()
                    .environment(ascClient)
            }
            else {
                AuthPage()
            }
        }
        .onChange(of: self.authState.credentials, initial: true) { _, newValue in
            self.ascClient = newValue.map(ASCClient.init(credentials:))
        }
    }
}
