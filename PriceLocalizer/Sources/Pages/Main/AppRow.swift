import SwiftUI

struct AppRow: View {
    let app: ASCApp

    @Environment(ASCClient.self) private var ascClient
    @State private var iconURL: URL?
    @State private var isHovered: Bool = false

    private let shape = RoundedRectangle(cornerRadius: 16)

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: self.iconURL) { image in
                image.resizable()
            } placeholder: {
                Rectangle()
                    .fill(.tertiary)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(self.app.attributes.name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(self.app.attributes.bundleId)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background {
            if self.isHovered {
                Color.secondary
                    .opacity(0.1)
                    .clipShape(self.shape)
                    .glassEffect(.regular, in: self.shape)
            }
        }
        .overlay {
            self.shape
                .strokeBorder(.separator, lineWidth: 1)
                .opacity(self.isHovered ? 1 : 0)
        }
        .contentShape(self.shape)
        .onHover { self.isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: self.isHovered)
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
