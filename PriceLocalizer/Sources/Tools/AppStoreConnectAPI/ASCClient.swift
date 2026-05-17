import Foundation
import Observation

@Observable
final class ASCClient: @unchecked Sendable {
    enum ASCError: Error {
        case http(statusCode: Int, body: String)
        case badURL(String)
    }

    private static let baseURL = "https://api.appstoreconnect.apple.com"

    private let tokens: TokenCache

    init(credentials: Credentials) {
        self.tokens = TokenCache(credentials: credentials)
    }

    func loadApps() async throws -> [ASCApp] {
        let response: ListResponse<ASCApp> = try await self.get("/v1/apps")
        return response.data
    }

    func loadAppIconURL(appID: String, size: Int = 512) async throws -> URL? {
        let path = "/v1/builds"
            + "?filter[app]=\(appID)&limit=1&sort=-uploadedDate&fields[builds]=iconAssetToken"
        let response: ListResponse<ASCAppBuild> = try await self.get(path)
        return response.data.first?.attributes.iconAssetToken?.url(size: size)
    }

    func loadInAppPurchases(appID: String) async throws -> [ASCInAppPurchase] {
        let path = "/v1/apps/\(appID)/inAppPurchasesV2"
            + "?limit=200&fields[inAppPurchases]=name,productId,inAppPurchaseType"
        let response: ListResponse<ASCInAppPurchase> = try await self.get(path)
        return response.data
    }

    func loadSubscriptionGroups(appID: String) async throws -> [ASCSubscriptionGroup] {
        let path = "/v1/apps/\(appID)/subscriptionGroups"
            + "?limit=200&include=subscriptions"
            + "&fields[subscriptionGroups]=referenceName,subscriptions"
            + "&fields[subscriptions]=name,productId"
        let response: SubscriptionGroupsResponse = try await self.get(path)
        let subsByID = Dictionary(
            uniqueKeysWithValues: (response.included ?? []).map { ($0.id, ASCSubscription(id: $0.id, attributes: $0.attributes)) },
        )
        return response.data.map { group in
            let subs = group.relationships.subscriptions.data.compactMap { subsByID[$0.id] }
            return ASCSubscriptionGroup(
                id: group.id,
                referenceName: group.attributes.referenceName,
                subscriptions: subs,
            )
        }
    }

    // MARK: - Private

    private struct ListResponse<T: Decodable & Sendable>: Decodable, Sendable {
        let data: [T]
    }

    private struct SubscriptionGroupsResponse: Decodable, Sendable {
        let data: [GroupResource]
        let included: [SubscriptionResource]?

        struct GroupResource: Decodable, Sendable {
            let id: String
            let attributes: Attributes
            let relationships: Relationships

            struct Attributes: Decodable, Sendable {
                let referenceName: String
            }

            struct Relationships: Decodable, Sendable {
                let subscriptions: Subscriptions

                struct Subscriptions: Decodable, Sendable {
                    let data: [Identifier]

                    struct Identifier: Decodable, Sendable {
                        let id: String
                    }
                }
            }
        }

        struct SubscriptionResource: Decodable, Sendable {
            let id: String
            let attributes: ASCSubscription.Attributes
        }
    }

    private func get<T: Decodable & Sendable>(
        _ pathOrURL: String,
        as: T.Type = T.self
    ) async throws -> T {
        let url = try Self.makeURL(pathOrURL)
        var req = URLRequest(url: url)
        let token = try await self.tokens.token()
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard
            let http = response as? HTTPURLResponse,
            (200 ..< 300).contains(http.statusCode)
        else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ASCError.http(statusCode: code, body: body)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func makeURL(_ pathOrURL: String) throws -> URL {
        let raw = pathOrURL.hasPrefix("http") ? pathOrURL : Self.baseURL + pathOrURL
        guard let url = URLComponents(string: raw)?.url else {
            throw ASCError.badURL(pathOrURL)
        }
        return url
    }
}
