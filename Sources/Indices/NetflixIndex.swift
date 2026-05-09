import Foundation

private let SINGLE: [String: IndexEntry] = [
    "USA": IndexEntry(currency: "USD", localPrice: 15.49),
    "ARG": IndexEntry(currency: "ARS", localPrice: 4699),
    "AUS": IndexEntry(currency: "AUD", localPrice: 18.99),
    "BRA": IndexEntry(currency: "BRL", localPrice: 39.90),
    "GBR": IndexEntry(currency: "GBP", localPrice: 10.99),
    "CAN": IndexEntry(currency: "CAD", localPrice: 16.49),
    "CHL": IndexEntry(currency: "CLP", localPrice: 8500),
    "COL": IndexEntry(currency: "COP", localPrice: 35900),
    "CZE": IndexEntry(currency: "CZK", localPrice: 299),
    "DNK": IndexEntry(currency: "DKK", localPrice: 119),
    "EGY": IndexEntry(currency: "EGP", localPrice: 165),
    "HKG": IndexEntry(currency: "HKD", localPrice: 88),
    "HUN": IndexEntry(currency: "HUF", localPrice: 3490),
    "IND": IndexEntry(currency: "INR", localPrice: 499),
    "IDN": IndexEntry(currency: "IDR", localPrice: 153000),
    "ISR": IndexEntry(currency: "ILS", localPrice: 49.90),
    "JPN": IndexEntry(currency: "JPY", localPrice: 1490),
    "MYS": IndexEntry(currency: "MYR", localPrice: 35),
    "MEX": IndexEntry(currency: "MXN", localPrice: 219),
    "NZL": IndexEntry(currency: "NZD", localPrice: 19.99),
    "NOR": IndexEntry(currency: "NOK", localPrice: 169),
    "PHL": IndexEntry(currency: "PHP", localPrice: 399),
    "POL": IndexEntry(currency: "PLN", localPrice: 53),
    "SAU": IndexEntry(currency: "SAR", localPrice: 49),
    "SGP": IndexEntry(currency: "SGD", localPrice: 17.98),
    "ZAF": IndexEntry(currency: "ZAR", localPrice: 169),
    "KOR": IndexEntry(currency: "KRW", localPrice: 13500),
    "SWE": IndexEntry(currency: "SEK", localPrice: 139),
    "CHE": IndexEntry(currency: "CHF", localPrice: 23.50),
    "TWN": IndexEntry(currency: "TWD", localPrice: 330),
    "THA": IndexEntry(currency: "THB", localPrice: 419),
    "TUR": IndexEntry(currency: "TRY", localPrice: 113.99),
    "ARE": IndexEntry(currency: "AED", localPrice: 39),
    "VNM": IndexEntry(currency: "VND", localPrice: 220000),
]

let NetflixIndex: PriceIndex = StaticPriceIndex(
    id: "netflix",
    label: "Netflix Index",
    data: withEuroArea(SINGLE, euroPrice: 13.49)
)
