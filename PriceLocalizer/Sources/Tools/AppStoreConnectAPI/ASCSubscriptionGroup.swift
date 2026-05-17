import Foundation

struct ASCSubscriptionGroup: Identifiable, Sendable {
    let id: String
    let referenceName: String
    let subscriptions: [ASCSubscription]
}
