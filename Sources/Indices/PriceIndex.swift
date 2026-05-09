import Foundation

struct IndexEntry: Sendable, Hashable {
    let currency: String
    let localPrice: Double
}

protocol PriceIndex: Sendable {
    var id: String { get }
    var label: String { get }
    func lookup(alpha3: String) -> IndexEntry?
    func territories() -> [String]
}

let EURO_AREA: [String] = [
    "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC", "HRV",
    "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK", "SVN",
]

func withEuroArea(
    _ map: [String: IndexEntry],
    euroPrice: Double
) -> [String: IndexEntry] {
    var out = map
    for code in EURO_AREA where out[code] == nil {
        out[code] = IndexEntry(currency: "EUR", localPrice: euroPrice)
    }
    return out
}

struct StaticPriceIndex: PriceIndex {
    let id: String
    let label: String
    let data: [String: IndexEntry]

    func lookup(alpha3: String) -> IndexEntry? { data[alpha3] }
    func territories() -> [String] { Array(data.keys) }
}
