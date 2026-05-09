import SwiftUI

struct PricesDetailView: View {
    @Environment(AppSession.self) private var session
    let subscription: Subscription

    @State private var prices: [PriceRow] = []
    @State private var loading = false
    @State private var error: String?

    @State private var selectedIndexId: String = INDEXES.first?.id ?? ""
    @State private var basePrice: String = ""
    @State private var pricePoints: [SubscriptionPricePoint] = []
    @State private var loadingPoints = false
    @State private var diffs: [PriceDiff] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 12) {
                Picker("Index", selection: $selectedIndexId) {
                    ForEach(INDEXES, id: \.id) { idx in
                        Text(idx.label).tag(idx.id)
                    }
                }
                .frame(maxWidth: 220)

                BaseCountryPicker(country: Binding(
                    get: { session.baseCountry },
                    set: { session.setBaseCountry($0) }
                ))
                .frame(maxWidth: 280)

                if pricePoints.isEmpty {
                    TextField("Base price", text: $basePrice)
                        .frame(maxWidth: 140)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("Base price", selection: $basePrice) {
                        ForEach(pricePoints, id: \.id) { p in
                            Text(p.customerPriceRaw).tag(p.customerPriceRaw)
                        }
                    }
                    .frame(maxWidth: 220)
                }

                Button("Preview") { preview() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(basePrice.isEmpty)

                Spacer()
            }

            if let error {
                Text(error).foregroundStyle(.red)
            }

            if loading {
                ProgressView().padding(.top, 24)
            } else if !diffs.isEmpty {
                diffTable
            } else {
                priceTable
            }
        }
        .padding(20)
        .task(id: subscription.id) { await loadPrices() }
        .onChange(of: session.baseCountry) { _, _ in
            Task { await loadPricePoints() }
        }
        .onChange(of: prices) { _, _ in
            Task { await loadPricePoints() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subscription.name).font(.title2.bold())
            Text("\(subscription.productId)  ·  \(subscription.groupName)")
                .foregroundStyle(.secondary)
        }
    }

    private var priceTable: some View {
        Table(prices) {
            TableColumn("Code", value: \.territory).width(min: 50, ideal: 60)
            TableColumn("Territory", value: \.territoryName)
            TableColumn("Currency", value: \.currency).width(min: 70, ideal: 80)
            TableColumn("Customer", value: \.customerPrice).width(min: 80, ideal: 100)
            TableColumn("Proceeds", value: \.proceeds).width(min: 80, ideal: 100)
        }
    }

    private var diffTable: some View {
        Table(diffs) {
            TableColumn("Code") { Text($0.territory) }.width(min: 50, ideal: 60)
            TableColumn("Territory") { Text($0.territoryName) }
            TableColumn("Currency") { Text($0.currency) }.width(min: 70, ideal: 80)
            TableColumn("Current") { Text(format($0.current)) }.width(min: 80, ideal: 100)
            TableColumn("Target") { Text(format($0.target)) }.width(min: 80, ideal: 100)
            TableColumn("Δ%") { d in
                if let pct = d.deltaPct {
                    Text(formatDelta(pct))
                        .foregroundStyle(pct >= 0 ? .green : .red)
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
            .width(min: 70, ideal: 90)
            TableColumn("Note") { Text($0.note ?? "") }
        }
    }

    private func format(_ v: Double?) -> String {
        guard let v else { return "—" }
        return v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.2f", v)
    }

    private func formatDelta(_ pct: Double) -> String {
        let sign = pct > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))%"
    }

    private func loadPrices() async {
        guard let creds = session.credentials else { return }
        loading = true
        defer { loading = false }
        diffs = []
        do {
            let client = AscClient(tokens: TokenCache(credentials: creds))
            prices = try await client.listSubscriptionPrices(subscriptionId: subscription.id)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadPricePoints() async {
        guard let creds = session.credentials else { return }
        let country = session.baseCountry
        loadingPoints = true
        defer { loadingPoints = false }
        do {
            let client = AscClient(tokens: TokenCache(credentials: creds))
            let points = try await client.listSubscriptionPricePoints(
                subscriptionId: subscription.id,
                territory: country
            )
            await MainActor.run {
                pricePoints = points
                if let current = prices.first(where: { $0.territory == country })?.customerPrice,
                   points.contains(where: { $0.customerPriceRaw == current }) {
                    basePrice = current
                } else if let first = points.first {
                    basePrice = first.customerPriceRaw
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func preview() {
        guard let index = indexById(selectedIndexId) else { return }
        guard let value = Double(basePrice) else {
            error = "Base price must be a number"
            return
        }
        do {
            diffs = try PppCalculator.calculate(
                basePrice: value,
                baseTerritory: session.baseCountry,
                rows: prices,
                index: index
            )
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
