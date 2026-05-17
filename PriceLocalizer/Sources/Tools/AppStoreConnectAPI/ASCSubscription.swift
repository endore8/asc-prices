import Foundation

struct ASCSubscription: Identifiable, Decodable, Sendable {
    let id: String
    let attributes: Attributes

    struct Attributes: Decodable, Sendable {
        let name: String
        let productId: String
    }
}
