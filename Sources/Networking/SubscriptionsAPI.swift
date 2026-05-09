import Foundation

struct Subscription: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let productId: String
    let groupName: String
}

extension AscClient {
    func listSubscriptions(appId: String) async throws -> [Subscription] {
        struct Response: Decodable {
            struct Group: Decodable {
                let id: String
                struct Attrs: Decodable {
                    let referenceName: String
                }
                struct Relationships: Decodable {
                    struct Subs: Decodable {
                        struct Ref: Decodable {
                            let id: String
                            let type: String
                        }
                        let data: [Ref]?
                    }
                    let subscriptions: Subs?
                }
                let attributes: Attrs
                let relationships: Relationships?
            }
            struct Included: Decodable {
                let id: String
                let type: String
                struct Attrs: Decodable {
                    let name: String
                    let productId: String
                }
                let attributes: Attrs
            }
            let data: [Group]
            let included: [Included]?
        }

        let res: Response = try await get(
            "/v1/apps/\(appId)/subscriptionGroups"
                + "?include=subscriptions"
                + "&fields[subscriptionGroups]=referenceName,subscriptions"
                + "&fields[subscriptions]=name,productId"
                + "&limit=200"
        )

        var subById: [String: (name: String, productId: String)] = [:]
        for inc in res.included ?? [] where inc.type == "subscriptions" {
            subById[inc.id] = (inc.attributes.name, inc.attributes.productId)
        }

        var out: [Subscription] = []
        for group in res.data {
            let groupName = group.attributes.referenceName
            for ref in group.relationships?.subscriptions?.data ?? [] {
                guard let sub = subById[ref.id] else { continue }
                out.append(Subscription(
                    id: ref.id,
                    name: sub.name,
                    productId: sub.productId,
                    groupName: groupName
                ))
            }
        }
        return out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
