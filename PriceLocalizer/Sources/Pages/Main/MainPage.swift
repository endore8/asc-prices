import SwiftUI

struct MainPage: View {
    @State private var selectedAppID: String?

    var body: some View {
        NavigationSplitView {
            VStack {
                AppsList(selectedAppID: self.$selectedAppID)
                Divider()
                SidebarFooter()
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } content: {
            List {
                Text(self.selectedAppID ?? "Content")
                    .foregroundStyle(.secondary)
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            Text(self.selectedAppID ?? "Detail")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
