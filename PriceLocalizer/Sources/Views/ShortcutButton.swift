import SwiftUI

struct ShortcutButton: View {
    let title: String
    let shortcut: Shortcut?
    let action: () -> Void

    struct Shortcut {
        let key: KeyboardShortcut
        let hint: String
    }

    init(
        title: String,
        shortcut: Shortcut? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 6) {
                Text(self.title)
                if let hint = self.shortcut?.hint {
                    KeyHint(hint)
                }
            }
        }
        .controlSize(.large)
        .buttonStyle(.glass)
        .keyboardShortcut(self.shortcut?.key)
    }
}

private struct KeyHint: View {
    let label: String

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.appearsActive) private var appearsActive

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(self.label)
            .font(.caption2)
            .foregroundStyle(.primary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .opacity(self.effectiveOpacity)
            .fixedSize()
    }

    private var effectiveOpacity: Double {
        if !self.isEnabled || !self.appearsActive { return 0.4 }
        return 1
    }
}
