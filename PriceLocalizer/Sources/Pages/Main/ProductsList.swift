import SwiftUI

struct ProductsList: View {
    let selectedAppID: String?

    var body: some View {
        if let selectedAppID = self.selectedAppID {
            List {
                Text(selectedAppID)
                    .foregroundStyle(.secondary)
            }
        }
        else {
            ContentUnavailableView(
                "No App Selected",
                systemImage: "square.dashed",
                description: Text("Pick an app from the sidebar to see its content."),
            )
        }
    }
}
