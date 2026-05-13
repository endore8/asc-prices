import Foundation

let INDEXES: [PriceIndex] = [NetflixIndex]

func indexById(_ id: String) -> PriceIndex? {
    INDEXES.first { $0.id == id }
}
