import SwiftUI

struct MainPage: View {
    @Environment(AuthState.self) private var authState
    @Environment(ASCClient.self) private var ascClient

    @State private var apps: [ASCApp]?

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                self.sidebarList

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
            .task(id: ObjectIdentifier(self.ascClient)) { await self.loadApps() }
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

    @ViewBuilder
    private var sidebarList: some View {
        if let apps = self.apps {
            List(apps) { app in
                AppRow(app: app)
            }
        }
        else {
            VStack {
                ProgressView()
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func logout() {
        self.authState.clearCredentials()
    }

    private func loadApps() async {
        do {
            self.apps = try await self.ascClient.loadApps()
        }
        catch {
            print("Failed to load apps: \(error)")
            self.apps = []
        }
    }
}

