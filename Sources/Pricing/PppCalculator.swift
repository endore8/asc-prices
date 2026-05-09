import Foundation

struct PriceDiff: Sendable, Identifiable, Hashable {
    var id: String { territory }
    let territory: String
    let territoryName: String
    let currency: String
    let current: Double?
    let target: Double?
    let deltaPct: Double?
    let note: String?
}

private let NO_MINOR_UNITS: Set<String> = [
    "JPY", "KRW", "VND", "IDR", "CLP", "ISK", "HUF",
]

enum PppCalculator {
    static func calculate(
        basePrice: Double,
        baseTerritory: String,
        rows: [PriceRow],
        index: PriceIndex
    ) throws -> [PriceDiff] {
        guard let baseEntry = index.lookup(alpha3: baseTerritory) else {
            throw CalcError.missingBase(country: baseTerritory, index: index.label)
        }

        return rows.map { row in
            let current = Double(row.customerPrice)
            guard let entry = index.lookup(alpha3: row.territory) else {
                return diff(row: row, current: current, note: "no \(index.label) data")
            }
            guard entry.currency == row.currency else {
                return diff(
                    row: row,
                    current: current,
                    note: "currency mismatch (\(index.label) uses \(entry.currency))"
                )
            }
            let raw = basePrice * (entry.localPrice / baseEntry.localPrice)
            let target = round(raw, currency: row.currency)
            let delta: Double? = {
                guard let cur = current, cur > 0 else { return nil }
                return (target - cur) / cur * 100
            }()
            return PriceDiff(
                territory: row.territory,
                territoryName: row.territoryName,
                currency: row.currency,
                current: current,
                target: target,
                deltaPct: delta,
                note: nil
            )
        }
    }

    private static func diff(row: PriceRow, current: Double?, note: String) -> PriceDiff {
        PriceDiff(
            territory: row.territory,
            territoryName: row.territoryName,
            currency: row.currency,
            current: current,
            target: nil,
            deltaPct: nil,
            note: note
        )
    }

    private static func round(_ value: Double, currency: String) -> Double {
        if NO_MINOR_UNITS.contains(currency) {
            return (value).rounded()
        }
        return ((value * 100).rounded()) / 100
    }

    enum CalcError: Error, LocalizedError {
        case missingBase(country: String, index: String)

        var errorDescription: String? {
            switch self {
            case .missingBase(let country, let index):
                return "Base country \(country) has no \(index) data."
            }
        }
    }
}
