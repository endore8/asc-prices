import SwiftUI

struct MainSplitView: View {
    @Environment(AppSession.self) private var session

    @State private var apps: [AscApp] = []
    @State private var selectedAppId: AscApp.ID?
    @State private var subscriptions: [Subscription] = []
    @State private var selectedSubscriptionId: Subscription.ID?
    @State private var loadingApps = false
    @State private var loadingSubs = false
    @State private var error: String?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } content: {
            content
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 380)
        } detail: {
            detail
        }
        .task { await loadApps() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    session.clearCredentials()
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selectedAppId) {
            Section("Apps") {
                if loadingApps && apps.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                }
                ForEach(apps) { app in
                    VStack(alignment: .leading) {
                        Text(app.name)
                            .lineLimit(1)
                        Text(app.bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .tag(Optional(app.id))
                }
            }
        }
        .onChange(of: selectedAppId) { _, newId in
            subscriptions = []
            selectedSubscriptionId = nil
            guard let newId else { return }
            Task { await loadSubscriptions(appId: newId) }
        }
    }

    private var content: some View {
        Group {
            if selectedAppId == nil {
                placeholder("Select an app")
            } else if loadingSubs && subscriptions.isEmpty {
                ProgressView()
            } else if subscriptions.isEmpty {
                placeholder("No subscriptions")
            } else {
                List(selection: $selectedSubscriptionId) {
                    Section("Subscriptions") {
                        ForEach(subscriptions) { sub in
                            VStack(alignment: .leading) {
                                Text(sub.name)
                                    .lineLimit(1)
                                Text("\(sub.productId)  ·  \(sub.groupName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .tag(Optional(sub.id))
                        }
                    }
                }
            }
        }
    }

    private var detail: some View {
        Group {
            if let id = selectedSubscriptionId,
               let sub = subscriptions.first(where: { $0.id == id }) {
                PricesDetailView(subscription: sub)
            } else {
                placeholder("Select a subscription")
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadApps() async {
        guard let creds = session.credentials else { return }
        loadingApps = true
        defer { loadingApps = false }
        do {
            let client = AscClient(tokens: TokenCache(credentials: creds))
            apps = try await client.listApps()
            if selectedAppId == nil {
                selectedAppId = apps.first?.id
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadSubscriptions(appId: String) async {
        guard let creds = session.credentials else { return }
        loadingSubs = true
        defer { loadingSubs = false }
        do {
            let client = AscClient(tokens: TokenCache(credentials: creds))
            subscriptions = try await client.listSubscriptions(appId: appId)
            selectedSubscriptionId = subscriptions.first?.id
        } catch {
            self.error = error.localizedDescription
        }
    }
}
