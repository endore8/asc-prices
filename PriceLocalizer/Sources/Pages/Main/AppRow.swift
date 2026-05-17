import SwiftUI

struct AppRow: View {
    let app: ASCApp

    @Environment(ASCClient.self) private var ascClient
    @State private var iconURL: URL?

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: self.iconURL) { image in
                image.resizable()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.tertiary)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(self.app.attributes.name)
                    .lineLimit(1)
                Text(self.app.attributes.bundleId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .task(id: self.app.id) { await self.loadIcon() }
    }

    private func loadIcon() async {
        do {
            self.iconURL = try await self.ascClient.loadAppIconURL(appID: self.app.id, size: 64)
        }
        catch {
            print("Failed to load icon for \(self.app.id): \(error)")
        }
    }
}
