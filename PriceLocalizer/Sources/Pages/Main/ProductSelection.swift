import Foundation

enum ProductSelection: Hashable, Sendable {
    case inAppPurchase(id: String)
    case subscription(id: String)

    var id: String {
        switch self {
        case .inAppPurchase(let id), .subscription(let id):
            return id
        }
    }
}
