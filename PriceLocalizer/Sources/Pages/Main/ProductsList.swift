import SwiftUI

struct ProductsList: View {
    let selectedAppID: String?

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
        else {
            List {
                if let iaps = self.inAppPurchases, !iaps.isEmpty {
                    Section("In-App Purchases") {
                        ForEach(iaps) { iap in
                            ProductRow(
                                name: iap.attributes.name,
                                productId: iap.attributes.productId,
                            )
                        }
                    }
                }

                if let groups = self.subscriptionGroups {
                    ForEach(groups) { group in
                        Section("Subscriptions · \(group.referenceName)") {
                            ForEach(group.subscriptions) { sub in
                                ProductRow(
                                    name: sub.attributes.name,
                                    productId: sub.attributes.productId,
                                )
                            }
                        }
                    }
                }
            }
        }
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
            print("Failed to load products for \(appID): \(error)")
            self.inAppPurchases = []
            self.subscriptionGroups = []
        }
    }
}

private struct ProductRow: View {
    let name: String
    let productId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.name)
            Text(self.productId)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
