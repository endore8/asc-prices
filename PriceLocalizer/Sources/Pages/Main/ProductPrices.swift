import SwiftUI

struct ProductPrices: View {
    let selectedProduct: ProductSelection?

    @Environment(ASCClient.self) private var ascClient

    @State private var prices: [ASCProductPrice]?

    var body: some View {
        Group {
            if let selection = self.selectedProduct {
                self.content(for: selection)
            }
            else {
                ContentUnavailableView(
                    "No Product Selected",
                    systemImage: "rectangle.dashed",
                    description: Text("Pick a product to see its current prices."),
                )
            }
        }
        .task(id: self.selectedProduct) { await self.loadPrices() }
    }

    @ViewBuilder
    private func content(for selection: ProductSelection) -> some View {
        if let prices = self.prices {
            if prices.isEmpty {
                ContentUnavailableView(
                    "No Prices",
                    systemImage: "tag",
                    description: Text("This product has no configured prices yet."),
                )
            }
            else {
                Table(Self.sortPrices(prices)) {
                    TableColumn("Country") { price in
                        Text(Self.countryName(for: price.territoryCode))
                            .fontWeight(.medium)
                    }
                    TableColumn("Currency") { price in
                        Text(price.currency)
                    }
                    TableColumn("Price") { price in
                        Text(price.customerPrice)
                    }
                    TableColumn("Proceeds (USD)") { price in
                        Text(price.proceedsUSD ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    TableColumn("Price (USD)") { price in
                        Text(price.customerPriceUSD ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        else {
            VStack {
                ProgressView()
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Private

    private static func countryName(for territoryCode: String) -> String {
        Locale.current.localizedString(forRegionCode: territoryCode) ?? territoryCode
    }

    private static func sortPrices(_ prices: [ASCProductPrice]) -> [ASCProductPrice] {
        prices.sorted { lhs, rhs in
            if lhs.territoryCode == "USA" { return true }
            if rhs.territoryCode == "USA" { return false }
            return Self.countryName(for: lhs.territoryCode) < Self.countryName(for: rhs.territoryCode)
        }
    }

    // MARK: - Actions

    private func loadPrices() async {
        self.prices = nil

        guard let selection = self.selectedProduct else { return }

        do {
            self.prices = try await self.ascClient.loadProductPrices(for: selection)
        }
        catch {
            guard !Task.isCancelled else { return }
            print("Failed to load prices for \(selection): \(error)")
            self.prices = []
        }
    }
}
