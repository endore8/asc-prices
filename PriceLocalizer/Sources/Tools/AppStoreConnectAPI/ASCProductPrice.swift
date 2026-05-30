import Foundation

struct ASCProductPrice: Identifiable, Sendable {
    let id: String
    let territoryCode: String
    let currency: String
    let customerPrice: String
    let proceeds: String
    let customerPriceUSD: String?
    let proceedsUSD: String?
}
