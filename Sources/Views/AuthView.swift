import SwiftUI
import UniformTypeIdentifiers

struct AuthView: View {
    @Environment(AppSession.self) private var session

    @State private var keyId: String = ""
    @State private var issuerId: String = ""
    @State private var keyURL: URL?
    @State private var keyPEM: String = ""
    @State private var keyFilename: String = ""
    @State private var error: String?
    @State private var importing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect to App Store Connect")
                .font(.title2.bold())

            Text("Generate an API key in App Store Connect → Users and Access → Integrations → App Store Connect API. The key needs the App Manager role.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button {
                            importing = true
                        } label: {
                            Label(keyFilename.isEmpty ? "Choose .p8 file…" : keyFilename, systemImage: "doc.badge.gearshape")
                        }
                        .buttonStyle(.bordered)

                        if !keyFilename.isEmpty {
                            Button(role: .destructive) {
                                keyFilename = ""
                                keyPEM = ""
                                keyURL = nil
                                keyId = inferredKeyId(from: nil) ?? keyId
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    LabeledContent("Key ID") {
                        TextField("ABC123DEFG", text: $keyId)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 280)
                    }

                    LabeledContent("Issuer ID") {
                        TextField("UUID", text: $issuerId)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 360)
                    }
                }
                .padding(8)
            }

            if let error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Save & Continue") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(maxWidth: 560)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [UTType(filenameExtension: "p8") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let url = try result.get().first else { return }
                let data = try Data(contentsOf: url)
                guard let pem = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "AuthView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read .p8 as UTF-8 text"])
                }
                keyPEM = pem
                keyURL = url
                keyFilename = url.lastPathComponent
                if let inferred = inferredKeyId(from: url.lastPathComponent), keyId.isEmpty {
                    keyId = inferred
                }
                error = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private var canSave: Bool {
        !keyPEM.isEmpty && !keyId.isEmpty && !issuerId.isEmpty
    }

    private func save() {
        do {
            let creds = Credentials(
                keyId: keyId.trimmingCharacters(in: .whitespaces),
                issuerId: issuerId.trimmingCharacters(in: .whitespaces),
                privateKeyPEM: keyPEM
            )
            try session.setCredentials(creds)
            error = nil
        } catch {
            self.error = "Could not save: \(error.localizedDescription)"
        }
    }

    private func inferredKeyId(from filename: String?) -> String? {
        guard let filename else { return nil }
        let pattern = #/AuthKey_([A-Z0-9]{10})\.p8/#.ignoresCase()
        if let match = filename.firstMatch(of: pattern) {
            return String(match.output.1).uppercased()
        }
        return nil
    }
}
