import SwiftUI

struct MainPage: View {
    @State private var selectedAppID: String?
    @State private var selectedProduct: ProductSelection?

    var body: some View {
        NavigationSplitView {
            VStack {
                AppsList(selectedAppID: self.$selectedAppID)
                Divider()
                SidebarFooter()
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } content: {
            ProductsList(
                selectedAppID: self.selectedAppID,
                selectedProduct: self.$selectedProduct,
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 280, max: 320)
        } detail: {
            ProductPrices(selectedProduct: self.selectedProduct)
        }
        .onChange(of: self.selectedAppID) { _, _ in
            self.selectedProduct = nil
        }
    }
}
