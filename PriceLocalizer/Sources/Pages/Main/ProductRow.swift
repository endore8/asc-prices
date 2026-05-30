import SwiftUI

struct ProductRow: View {
    let name: String
    let productId: String
    let selection: ProductSelection
    @Binding var selectedProduct: ProductSelection?

    @State private var isHovered: Bool = false

    private let shape = RoundedRectangle(cornerRadius: 12)

    private var isSelected: Bool {
        self.selectedProduct == self.selection
    }

    var body: some View {
        Button(action: self.select) {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.name)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(self.productId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .contentShape(self.shape)
        }
        .buttonStyle(.plain)
        .background {
            if self.isSelected || self.isHovered {
                Color.secondary
                    .opacity(0.1)
                    .clipShape(self.shape)
                    .glassEffect(.regular, in: self.shape)
            }
        }
        .overlay {
            self.shape
                .strokeBorder(
                    self.isSelected ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(.separator),
                    lineWidth: 1,
                )
                .opacity(self.isSelected || self.isHovered ? 1 : 0)
        }
        .onHover { self.isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: self.isHovered)
        .animation(.easeInOut(duration: 0.1), value: self.isSelected)
    }

    // MARK: - Actions

    private func select() {
        self.selectedProduct = self.selection
    }
}
