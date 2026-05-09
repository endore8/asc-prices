import Foundation

let INDEXES: [PriceIndex] = [NetflixIndex]

func indexById(_ id: String) -> PriceIndex? {
    INDEXES.first { $0.id == id }
}

func allBaseTerritories() -> [String] {
    var set = Set<String>()
    for index in INDEXES {
        for code in index.territories() {
            set.insert(code)
        }
    }
    return Array(set)
}
