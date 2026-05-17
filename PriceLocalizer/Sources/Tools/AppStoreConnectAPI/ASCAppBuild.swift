import Foundation

struct ASCAppBuild: Decodable, Sendable {
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let iconAssetToken: ImageAsset?
    }

    struct ImageAsset: Decodable, Sendable {
        let templateUrl: String

        func url(size: Int) -> URL? {
            let raw = self.templateUrl
                .replacingOccurrences(of: "{w}", with: String(size))
                .replacingOccurrences(of: "{h}", with: String(size))
                .replacingOccurrences(of: "{f}", with: "png")
            return URL(string: raw)
        }
    }
}
