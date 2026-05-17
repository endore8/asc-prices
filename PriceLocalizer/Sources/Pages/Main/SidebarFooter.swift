import SwiftUI

struct SidebarFooter: View {
    @Environment(AuthState.self) private var authState

    var body: some View {
        HStack {
            Button(action: self.logout) {
                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            Spacer()
        }
        .padding()
    }

    // MARK: - Actions

    private func logout() {
        self.authState.clearCredentials()
    }
}
