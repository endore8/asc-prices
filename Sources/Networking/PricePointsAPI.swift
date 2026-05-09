import Foundation

struct SubscriptionPricePoint: Identifiable, Sendable, Hashable {
    let id: String
    let customerPriceRaw: String
    let customerPrice: Double
    let proceeds: Double
}

extension AscClient {
    func listSubscriptionPricePoints(
        subscriptionId: String,
        territory: String
    ) async throws -> [SubscriptionPricePoint] {
        struct Response: Decodable {
            struct Item: Decodable {
                let id: String
                let type: String
                struct Attrs: Decodable {
                    let customerPrice: String
                    let proceeds: String
                }
                let attributes: Attrs
            }
            struct Links: Decodable {
                let next: String?
            }
            let data: [Item]
            let links: Links?
        }

        var seen: [String: SubscriptionPricePoint] = [:]
        var path: String? =
            "/v1/subscriptions/\(subscriptionId)/pricePoints"
                + "?filter[territory]=\(territory)"
                + "&fields[subscriptionPricePoints]=customerPrice,proceeds"
                + "&limit=200"

        while let current = path {
            let res: Response = try await get(current)
            for d in res.data {
                if seen[d.attributes.customerPrice] != nil { continue }
                guard let cp = Double(d.attributes.customerPrice) else { continue }
                let pr = Double(d.attributes.proceeds) ?? 0
                seen[d.attributes.customerPrice] = SubscriptionPricePoint(
                    id: d.id,
                    customerPriceRaw: d.attributes.customerPrice,
                    customerPrice: cp,
                    proceeds: pr
                )
            }
            path = res.links?.next
        }
        return Array(seen.values).sorted { $0.customerPrice < $1.customerPrice }
    }
}
