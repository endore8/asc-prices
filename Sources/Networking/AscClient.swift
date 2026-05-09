import Foundation

struct AscClient: Sendable {
    let tokens: TokenCache

    enum AscError: Error {
        case http(statusCode: Int, body: String)
        case badURL(String)
    }

    private static let baseURL = "https://api.appstoreconnect.apple.com"

    func get<T: Decodable & Sendable>(_ pathOrURL: String, as: T.Type = T.self) async throws -> T {
        let url = try Self.makeURL(pathOrURL)
        var req = URLRequest(url: url)
        let token = try await tokens.token()
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AscError.http(statusCode: code, body: body)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func makeURL(_ pathOrURL: String) throws -> URL {
        let raw = pathOrURL.hasPrefix("http") ? pathOrURL : baseURL + pathOrURL
        let encoded = raw
            .replacingOccurrences(of: "[", with: "%5B")
            .replacingOccurrences(of: "]", with: "%5D")
        guard let url = URL(string: encoded) else {
            throw AscError.badURL(pathOrURL)
        }
        return url
    }
}
