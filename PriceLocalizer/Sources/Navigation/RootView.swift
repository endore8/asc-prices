import SwiftUI

struct RootView: View {
    @Environment(AuthState.self) private var authState

    var body: some View {
        if self.authState.credentials != nil {
            MainPage()
        }
        else {
            AuthPage()
        }
    }
}
