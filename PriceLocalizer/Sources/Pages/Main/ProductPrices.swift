import SwiftUI

struct ProductPrices: View {
    let selectedAppID: String?

    var body: some View {
        if let selectedAppID = self.selectedAppID {
            Text(selectedAppID)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        else {
            ContentUnavailableView(
                "Nothing Selected",
                systemImage: "rectangle.dashed",
            )
        }
    }
}
