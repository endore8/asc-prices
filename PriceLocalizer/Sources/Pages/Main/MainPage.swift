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
            ProductsList(selectedAppID: self.selectedAppID)
                .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            ProductPrices(selectedAppID: self.selectedAppID)
        }
    }
}
