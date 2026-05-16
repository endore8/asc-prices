import SwiftUI
import UniformTypeIdentifiers

struct AuthKeyFilePicker: View {
    @Binding var filename: String
    @Binding var pem: String

    @State private var importing: Bool = false
    @State private var isTargeted: Bool = false
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: self.openFilePicker) {
            VStack {
                Image(systemName: "document.badge.arrow.up")
                    .font(.title)
                Text(
                    self.filename.isEmpty
                        ? "Drop or select the AuthKey_XXXX.p8 file"
                        : self.filename
                )
                .font(.callout)
                .multilineTextAlignment(.center)
            }
            .foregroundStyle(self.foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 100)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(self.borderColor, style: self.strokeStyle)
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: self.$isTargeted, perform: self.handleDrop)
        .onHover(perform: self.handleHover)
        .animation(.easeInOut(duration: 0.15), value: self.isHovered)
        .animation(.easeInOut(duration: 0.15), value: self.isTargeted)
        .animation(.easeInOut(duration: 0.15), value: self.filename.isEmpty)
        .fileImporter(
            isPresented: self.$importing,
            allowedContentTypes: [UTType(filenameExtension: "p8") ?? .data],
            allowsMultipleSelection: false,
            onCompletion: self.handleFileImport
        )
    }

    // MARK: - Styling

    private var fillColor: Color {
        if self.isTargeted { return Color.accentColor.opacity(0.1) }
        if !self.filename.isEmpty { return Color.accentColor.opacity(0.1) }
        if self.isHovered { return Color.secondary.opacity(0.05) }
        return Color.clear
    }

    private var borderColor: Color {
        if !self.filename.isEmpty { return Color.accentColor.opacity(0.2) }
        return Color.secondary.opacity(0.2)
    }

    private var foregroundColor: Color {
        self.filename.isEmpty ? Color.secondary : Color.accentColor
    }

    private var strokeStyle: StrokeStyle {
        if self.isHovered {
            return StrokeStyle(lineWidth: 1)
        }
        if self.isTargeted || !self.filename.isEmpty {
            return StrokeStyle(lineWidth: 1)
        }
        return StrokeStyle(lineWidth: 1, dash: [4])
    }

    // MARK: - Actions

    private func openFilePicker() {
        self.importing = true
    }

    private func handleHover(_ hovering: Bool) {
        self.isHovered = hovering
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        if let url = (try? result.get())?.first {
            self.loadKey(from: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url, url.pathExtension.lowercased() == "p8" else {
                return
            }
            Task { @MainActor in
                self.loadKey(from: url)
            }
        }
        return true
    }

    private func loadKey(from url: URL) {
        guard
            let data = try? Data(contentsOf: url),
            let text = String(data: data, encoding: .utf8)
        else {
            return
        }
        self.filename = url.lastPathComponent
        self.pem = text
    }
}
