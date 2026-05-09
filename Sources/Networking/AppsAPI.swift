import Foundation

struct AscApp: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let bundleId: String
    let sku: String
}

extension AscClient {
    func listApps() async throws -> [AscApp] {
        struct Response: Decodable {
            struct Item: Decodable {
                let id: String
                struct Attrs: Decodable {
                    let name: String
                    let bundleId: String
                    let sku: String
                }
                let attributes: Attrs
            }
            let data: [Item]
        }
        let res: Response = try await get(
            "/v1/apps?limit=200&fields[apps]=name,bundleId,sku"
        )
        return res.data.map {
            AscApp(
                id: $0.id,
                name: $0.attributes.name,
                bundleId: $0.attributes.bundleId,
                sku: $0.attributes.sku
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
