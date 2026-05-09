import Foundation

struct PriceRow: Identifiable, Sendable, Hashable {
    var id: String { territory }
    let territory: String
    let territoryName: String
    let currency: String
    let customerPrice: String
    let proceeds: String
}

extension AscClient {
    func listSubscriptionPrices(subscriptionId: String) async throws -> [PriceRow] {
        struct Response: Decodable {
            struct Item: Decodable {
                let id: String
                let type: String
                struct Relationships: Decodable {
                    struct Ref: Decodable { let id: String; let type: String }
                    struct Wrapper: Decodable { let data: Ref }
                    let subscriptionPricePoint: Wrapper
                    let territory: Wrapper
                }
                let relationships: Relationships
            }
            struct Included: Decodable {
                let id: String
                let type: String
                struct PricePointAttrs: Decodable {
                    let customerPrice: String
                    let proceeds: String
                }
                struct TerritoryAttrs: Decodable {
                    let currency: String
                }
                let attributes: AnyAttrs
            }
            let data: [Item]
            let included: [Included]?
        }

        struct AnyAttrs: Decodable {
            let customerPrice: String?
            let proceeds: String?
            let currency: String?
        }

        let res: Response = try await get(
            "/v1/subscriptions/\(subscriptionId)/prices"
                + "?include=subscriptionPricePoint,territory"
                + "&fields[subscriptionPrices]=subscriptionPricePoint,territory"
                + "&fields[subscriptionPricePoints]=customerPrice,proceeds"
                + "&fields[territories]=currency"
                + "&limit=200"
        )

        var pricePoints: [String: (String, String)] = [:]
        var territories: [String: String] = [:]
        for inc in res.included ?? [] {
            switch inc.type {
            case "subscriptionPricePoints":
                if let cp = inc.attributes.customerPrice, let pr = inc.attributes.proceeds {
                    pricePoints[inc.id] = (cp, pr)
                }
            case "territories":
                if let cur = inc.attributes.currency {
                    territories[inc.id] = cur
                }
            default:
                break
            }
        }

        let rows: [PriceRow] = res.data.compactMap { item in
            let ppId = item.relationships.subscriptionPricePoint.data.id
            let tId = item.relationships.territory.data.id
            let pp = pricePoints[ppId]
            return PriceRow(
                territory: tId,
                territoryName: TerritoryName.lookup(alpha3: tId) ?? "",
                currency: territories[tId] ?? "?",
                customerPrice: pp?.0 ?? "?",
                proceeds: pp?.1 ?? "?"
            )
        }
        return rows.sorted { $0.territoryName.localizedCaseInsensitiveCompare($1.territoryName) == .orderedAscending }
    }
}
