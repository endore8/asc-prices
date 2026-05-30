import SwiftUI

struct ProductsList: View {
    let selectedAppID: String?
    @Binding var selectedProduct: ProductSelection?

    @Environment(ASCClient.self) private var ascClient

    @State private var inAppPurchases: [ASCInAppPurchase]?
    @State private var subscriptionGroups: [ASCSubscriptionGroup]?

    var body: some View {
        Group {
            if let selectedAppID = self.selectedAppID {
                self.content(for: selectedAppID)
            }
            else {
                ContentUnavailableView(
                    "No App Selected",
                    systemImage: "square.dashed",
                    description: Text("Pick an app from the sidebar to see its content."),
                )
            }
        }
        .task(id: self.selectedAppID) { await self.loadProducts() }
    }

    @ViewBuilder
    private func content(for appID: String) -> some View {
        if self.inAppPurchases == nil, self.subscriptionGroups == nil {
            VStack {
                ProgressView()
                    .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        else if !self.hasAnyProducts {
            ContentUnavailableView(
                "No Products",
                systemImage: "shippingbox",
                description: Text("This app has no in-app purchases or subscriptions yet."),
            )
        }
        else {
            ScrollView {
                VStack(spacing: 2) {
                    if let iaps = self.inAppPurchases, !iaps.isEmpty {
                        SectionHeader(title: "In-App Purchases")
                        ForEach(iaps) { iap in
                            ProductRow(
                                name: iap.attributes.name,
                                productId: iap.attributes.productId,
                                selection: .inAppPurchase(id: iap.id),
                                selectedProduct: self.$selectedProduct,
                            )
                        }
                    }

                    if let groups = self.subscriptionGroups {
                        ForEach(groups) { group in
                            SectionHeader(title: "Subscriptions · \(group.referenceName)")
                            ForEach(group.subscriptions) { sub in
                                ProductRow(
                                    name: sub.attributes.name,
                                    productId: sub.attributes.productId,
                                    selection: .subscription(id: sub.id),
                                    selectedProduct: self.$selectedProduct,
                                )
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    private var hasAnyProducts: Bool {
        let hasIAPs = !(self.inAppPurchases ?? []).isEmpty
        let hasSubscriptions = (self.subscriptionGroups ?? []).contains { !$0.subscriptions.isEmpty }
        return hasIAPs || hasSubscriptions
    }

    // MARK: - Actions

    private func loadProducts() async {
        self.inAppPurchases = nil
        self.subscriptionGroups = nil

        guard let appID = self.selectedAppID else { return }

        do {
            async let iapsTask = self.ascClient.loadInAppPurchases(appID: appID)
            async let groupsTask = self.ascClient.loadSubscriptionGroups(appID: appID)
            let (iaps, groups) = try await (iapsTask, groupsTask)
            self.inAppPurchases = iaps
            self.subscriptionGroups = groups
        }
        catch {
            guard !Task.isCancelled else { return }
            print("Failed to load products for \(appID): \(error)")
            self.inAppPurchases = []
            self.subscriptionGroups = []
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
