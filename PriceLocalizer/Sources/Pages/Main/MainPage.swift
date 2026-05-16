import SwiftUI

struct MainPage: View {
    var body: some View {
        NavigationSplitView {
            List {
                Text("Sidebar")
                    .foregroundStyle(.secondary)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } content: {
            List {
                Text("Content")
                    .foregroundStyle(.secondary)
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 380)
        } detail: {
            Text("Detail")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
