import SwiftUI

struct AppsList: View {
    @Environment(ASCClient.self) private var ascClient

    @State private var apps: [ASCApp]?

    var body: some View {
        Group {
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
        .task(id: ObjectIdentifier(self.ascClient)) { await self.loadApps() }
    }

    // MARK: - Actions

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
