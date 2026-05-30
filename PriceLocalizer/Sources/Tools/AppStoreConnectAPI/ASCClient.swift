import Foundation
import Observation

@Observable
final class ASCClient: @unchecked Sendable {
    enum ASCError: Error {
        case http(statusCode: Int, body: String)
        case badURL(String)
    }

    private static let baseURL = "https://api.appstoreconnect.apple.com"

    private static let maxConcurrentEqualizationRequests = 6

    private let tokens: TokenCache
    private let equalizationCache = EqualizationCache()

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

    func loadProductPrices(for selection: ProductSelection) async throws -> [ASCProductPrice] {
        let pending: [PendingPrice]
        switch selection {
        case .inAppPurchase(let id):
            pending = try await self.loadInAppPurchasePrices(iapID: id)
        case .subscription(let id):
            pending = try await self.loadSubscriptionPrices(subscriptionID: id)
        }
        return try await self.attachUSDEquivalents(to: pending, for: selection)
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

    private struct PendingPrice: Sendable {
        let id: String
        let territoryCode: String
        let currency: String
        let customerPrice: String
        let proceeds: String
        let pricePointID: String
    }

    private func loadSubscriptionPrices(subscriptionID: String) async throws -> [PendingPrice] {
        let path = "/v1/subscriptions/\(subscriptionID)/prices"
            + "?limit=200&include=subscriptionPricePoint,territory"
            + "&fields[subscriptionPrices]=subscriptionPricePoint,territory"
            + "&fields[subscriptionPricePoints]=customerPrice,proceeds"
            + "&fields[territories]=currency"
        let response: PricesResponse = try await self.get(path)
        return Self.assemblePrices(
            from: response,
            pricePointType: "subscriptionPricePoints",
            pricePointKey: "subscriptionPricePoint",
        )
    }

    private func loadInAppPurchasePrices(iapID: String) async throws -> [PendingPrice] {
        let schedule: SingleResponse<ScheduleResource> = try await self.get(
            "/v2/inAppPurchases/\(iapID)/iapPriceSchedule",
        )
        let scheduleID = schedule.data.id

        async let manualTask = self.loadIAPSchedulePrices(scheduleID: scheduleID, kind: "manualPrices")
        async let automaticTask = self.loadIAPSchedulePrices(scheduleID: scheduleID, kind: "automaticPrices")
        let (manual, automatic) = try await (manualTask, automaticTask)

        let manualTerritories = Set(manual.map(\.territoryCode))
        return manual + automatic.filter { !manualTerritories.contains($0.territoryCode) }
    }

    private func loadIAPSchedulePrices(scheduleID: String, kind: String) async throws -> [PendingPrice] {
        let path = "/v1/inAppPurchasePriceSchedules/\(scheduleID)/\(kind)"
            + "?limit=200&include=inAppPurchasePricePoint,territory"
            + "&fields[inAppPurchasePrices]=inAppPurchasePricePoint,territory"
            + "&fields[inAppPurchasePricePoints]=customerPrice,proceeds"
            + "&fields[territories]=currency"
        let response: PricesResponse = try await self.get(path)
        return Self.assemblePrices(
            from: response,
            pricePointType: "inAppPurchasePricePoints",
            pricePointKey: "inAppPurchasePricePoint",
        )
    }

    private static func assemblePrices(
        from response: PricesResponse,
        pricePointType: String,
        pricePointKey: String,
    ) -> [PendingPrice] {
        let included = response.included ?? []
        let pricePoints = Dictionary(
            uniqueKeysWithValues: included
                .filter { $0.type == pricePointType }
                .compactMap { resource -> (String, (customerPrice: String, proceeds: String))? in
                    guard
                        let customerPrice = resource.attributes.customerPrice,
                        let proceeds = resource.attributes.proceeds
                    else {
                        return nil
                    }
                    return (resource.id, (customerPrice: customerPrice, proceeds: proceeds))
                },
        )
        let territories = Dictionary(
            uniqueKeysWithValues: included
                .filter { $0.type == "territories" }
                .compactMap { resource -> (String, String)? in
                    guard let currency = resource.attributes.currency else { return nil }
                    return (resource.id, currency)
                },
        )

        return response.data.compactMap { price -> PendingPrice? in
            guard
                let territoryID = price.relationships?["territory"]?.data?.id,
                let pricePointID = price.relationships?[pricePointKey]?.data?.id,
                let pricePoint = pricePoints[pricePointID],
                let currency = territories[territoryID]
            else {
                return nil
            }
            return PendingPrice(
                id: price.id,
                territoryCode: territoryID,
                currency: currency,
                customerPrice: pricePoint.customerPrice,
                proceeds: pricePoint.proceeds,
                pricePointID: pricePointID,
            )
        }
    }

    private func attachUSDEquivalents(
        to prices: [PendingPrice],
        for selection: ProductSelection,
    ) async throws -> [ASCProductPrice] {
        let usdByPricePoint = await self.fetchUSDEqualizations(for: prices, selection: selection)
        return prices.map { price in
            let usd: (customerPrice: String, proceeds: String)?
            if price.territoryCode == "USA" {
                usd = (price.customerPrice, price.proceeds)
            }
            else {
                usd = usdByPricePoint[price.pricePointID]
            }
            return ASCProductPrice(
                id: price.id,
                territoryCode: price.territoryCode,
                currency: price.currency,
                customerPrice: price.customerPrice,
                proceeds: price.proceeds,
                customerPriceUSD: usd?.customerPrice,
                proceedsUSD: usd?.proceeds,
            )
        }
    }

    private func fetchUSDEqualizations(
        for prices: [PendingPrice],
        selection: ProductSelection,
    ) async -> [String: (customerPrice: String, proceeds: String)] {
        let pricePointIDs = Array(Set(prices.filter { $0.territoryCode != "USA" }.map(\.pricePointID)))
        var iterator = pricePointIDs.makeIterator()
        var map: [String: (customerPrice: String, proceeds: String)] = [:]

        await withTaskGroup(
            of: (String, (customerPrice: String, proceeds: String)?).self,
        ) { group in
            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    let usd = try? await self.fetchUSDEqualization(
                        pricePointID: id,
                        selection: selection,
                    )
                    return (id, usd)
                }
            }

            for _ in 0 ..< Self.maxConcurrentEqualizationRequests {
                addNext()
            }

            while let (id, value) = await group.next() {
                if let value {
                    map[id] = value
                }
                addNext()
            }
        }
        return map
    }

    private func fetchUSDEqualization(
        pricePointID: String,
        selection: ProductSelection,
    ) async throws -> (customerPrice: String, proceeds: String)? {
        let cacheKey = EqualizationCache.Key(selection: selection, pricePointID: pricePointID)
        if let cached = await self.equalizationCache.value(for: cacheKey) {
            return (cached.customerPrice, cached.proceeds)
        }

        let basePath: String
        let fieldsKey: String
        switch selection {
        case .subscription:
            basePath = "/v1/subscriptionPricePoints/\(pricePointID)/equalizations"
            fieldsKey = "subscriptionPricePoints"
        case .inAppPurchase:
            basePath = "/v1/inAppPurchasePricePoints/\(pricePointID)/equalizations"
            fieldsKey = "inAppPurchasePricePoints"
        }
        let path = basePath
            + "?filter[territory]=USA&limit=1"
            + "&fields[\(fieldsKey)]=customerPrice,proceeds"
        let response: ListResponse<USDPricePoint> = try await self.get(path)
        guard let pp = response.data.first else { return nil }
        let value = EqualizationCache.USDPrice(
            customerPrice: pp.attributes.customerPrice,
            proceeds: pp.attributes.proceeds,
        )
        await self.equalizationCache.setValue(value, for: cacheKey)
        return (value.customerPrice, value.proceeds)
    }

    private actor EqualizationCache {
        private var entries: [Key: USDPrice] = [:]

        struct Key: Hashable, Sendable {
            let selection: SelectionKind
            let pricePointID: String

            init(selection: ProductSelection, pricePointID: String) {
                switch selection {
                case .subscription:
                    self.selection = .subscription
                case .inAppPurchase:
                    self.selection = .inAppPurchase
                }
                self.pricePointID = pricePointID
            }

            enum SelectionKind: Hashable, Sendable {
                case subscription
                case inAppPurchase
            }
        }

        struct USDPrice: Sendable {
            let customerPrice: String
            let proceeds: String
        }

        func value(for key: Key) -> USDPrice? {
            self.entries[key]
        }

        func setValue(_ value: USDPrice, for key: Key) {
            self.entries[key] = value
        }
    }

    private struct USDPricePoint: Decodable, Sendable {
        let attributes: Attributes

        struct Attributes: Decodable, Sendable {
            let customerPrice: String
            let proceeds: String
        }
    }

    private struct ListResponse<T: Decodable & Sendable>: Decodable, Sendable {
        let data: [T]
    }

    private struct SingleResponse<T: Decodable & Sendable>: Decodable, Sendable {
        let data: T
    }

    private struct ScheduleResource: Decodable, Sendable {
        let id: String
    }

    private struct PricesResponse: Decodable, Sendable {
        let data: [PriceResource]
        let included: [IncludedResource]?

        struct PriceResource: Decodable, Sendable {
            let id: String
            let relationships: [String: Relationship]?

            struct Relationship: Decodable, Sendable {
                let data: Identifier?

                struct Identifier: Decodable, Sendable {
                    let id: String
                }
            }
        }

        struct IncludedResource: Decodable, Sendable {
            let type: String
            let id: String
            let attributes: Attributes

            struct Attributes: Decodable, Sendable {
                let customerPrice: String?
                let proceeds: String?
                let currency: String?
            }
        }
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
