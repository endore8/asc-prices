import SwiftUI

struct AuthPage: View {
    @Environment(AuthState.self) private var authState

    @State private var keyId: String = ""
    @State private var issuerId: String = ""
    @State private var keyFilename: String = ""
    @State private var keyPEM: String = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case keyId, issuerId
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Authenticate")
                            .font(.title)
                            .foregroundStyle(.primary)
                        Text("Provide an Auth Key to authenticate with the App Store Connect API.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)

                    GroupBox(label:
                        Label("How to get an Auth Key", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.title3)
                            .padding(.bottom, 8)
                            .padding(.horizontal)
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(self.setupSteps.enumerated()), id: \.offset) { index, step in
                                InstructionStepRow(index: index, text: step)
                            }
                        }
                        .padding()
                    }

                    GroupBox(label:
                        Label("Credentials", systemImage: "key.card.fill")
                            .font(.title3)
                            .padding(.bottom, 8)
                            .padding(.horizontal)
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            AuthKeyFilePicker(filename: self.$keyFilename, pem: self.$keyPEM)

                            LabeledContent("Key ID") {
                                TextField("ABCDE12345", text: self.$keyId)
                                    .textFieldStyle(.roundedBorder)
                                    .focused(self.$focusedField, equals: .keyId)
                            }

                            LabeledContent("Issuer ID") {
                                TextField("abcdef12-3456-7890-abcd-ef1234567890", text: self.$issuerId)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .focused(self.$focusedField, equals: .issuerId)
                            }

                            GroupBox {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    Text("Credentials are securely stored and never leave your device.")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(8)
                            }
                        }
                        .labeledContentStyle(VerticalLabeledContentStyle())
                        .padding()
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: self.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }

            HStack {
                ShortcutButton(
                    title: "Clear",
                    shortcut: .init(key: .cancelAction, hint: "esc"),
                    action: self.clear
                )
                .disabled(!self.canClear)

                Spacer()

                ShortcutButton(
                    title: "Save",
                    shortcut: .init(key: KeyboardShortcut(.return, modifiers: .command), hint: "⌘ ⏎"),
                    action: self.save
                )
                .tint(.accentColor)
                .disabled(!self.canSave)
            }
            .padding()
            .frame(maxWidth: self.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) { Divider() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: self.keyFilename, self.handleKeyFilenameChange)
    }

    // MARK: - Content

    private let contentMaxWidth: CGFloat = 500

    private let setupSteps: [String] = [
        "Login to **[App Store Connect](https://appstoreconnect.apple.com)** 􀰾",
        "Navigate to **Users and Access** → **Integrations** → **Team Keys**",
        "Generate a new key with the **App Manager** role",
        "Download the .p8 file and select it in the file picker below",
        "Copy the Issuer ID from the same page and paste it below",
    ]

    // MARK: - Validation

    private var canSave: Bool {
        !self.keyPEM.isEmpty
            && self.keyId.count == 10
            && UUID(uuidString: self.issuerId) != nil
    }

    private var canClear: Bool {
        !self.keyPEM.isEmpty || !self.keyId.isEmpty || !self.issuerId.isEmpty
    }

    // MARK: - Actions

    private func deriveKeyId() {
        let pattern = #/AuthKey_([A-Z0-9]{10})\.p8/#.ignoresCase()
        if let match = self.keyFilename.firstMatch(of: pattern) {
            self.keyId = String(match.output.1).uppercased()
        }
    }

    private func handleKeyFilenameChange() {
        self.deriveKeyId()
        guard !self.keyFilename.isEmpty else { return }
        self.focusedField = self.keyId.isEmpty ? .keyId : .issuerId
    }

    private func clear() {
        self.keyId = ""
        self.issuerId = ""
        self.keyFilename = ""
        self.keyPEM = ""
    }

    private func save() {
        let credentials = Credentials(
            keyId: self.keyId,
            issuerId: self.issuerId,
            privateKeyPEM: self.keyPEM
        )
        self.authState.setCredentials(credentials)
    }
}

private struct InstructionStepRow: View {
    let index: Int
    let text: String

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "\(self.index + 1)")
                .symbolVariant(.circle)
                .font(.title3)
                .foregroundStyle(self.isHovered ? .primary : .secondary)
            Text(self.text.markdownWithUnderlinedLinks(linkColor: self.isHovered ? .primary : .secondary))
                .foregroundStyle(self.isHovered ? .primary : .secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onHover(perform: self.handleHover)
        .animation(.easeInOut(duration: 0.15), value: self.isHovered)
    }

    private func handleHover(_ hovering: Bool) {
        self.isHovered = hovering
    }
}
