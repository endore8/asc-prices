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

    // MARK: - Private

    private struct ListResponse<T: Decodable & Sendable>: Decodable, Sendable {
        let data: [T]
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
