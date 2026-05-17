import SwiftUI

struct MainPage: View {
    @Environment(AuthState.self) private var authState
    @Environment(ASCClient.self) private var ascClient

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List {
                    Text("Sidebar")
                        .foregroundStyle(.secondary)
                }

                Divider()

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
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } content: {
            List {
                Text("Content")
                    .foregroundStyle(.secondary)
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 380)
        } detail: {
            Text("Detail")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func logout() {
        self.authState.clearCredentials()
    }
}
