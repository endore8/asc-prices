import SwiftUI

struct MainPage: View {
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                AppsList()
                Divider()
                SidebarFooter()
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } content: {
            List {
                Text("Content")
                    .foregroundStyle(.secondary)
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            Text("Detail")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
