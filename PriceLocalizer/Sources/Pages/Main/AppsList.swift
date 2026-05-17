import SwiftUI

struct AppsList: View {
    @Binding var selectedAppID: String?

    @Environment(ASCClient.self) private var ascClient

    @State private var apps: [ASCApp]?

    var body: some View {
        Group {
            if let apps = self.apps {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(apps) { app in
                            AppRow(app: app, selectedAppID: self.$selectedAppID)
                        }
                    }
                    .padding(8)
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
