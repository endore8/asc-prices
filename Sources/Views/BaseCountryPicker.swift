import SwiftUI

struct BaseCountryPicker: View {
    @Binding var country: String

    private struct Entry: Identifiable, Hashable {
        let code: String
        let label: String
        var id: String { code }
    }

    private var entries: [Entry] {
        allBaseTerritories()
            .map { code in
                Entry(code: code, label: TerritoryName.lookup(alpha3: code) ?? code)
            }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    var body: some View {
        Picker("Base country", selection: $country) {
            ForEach(entries) { e in
                Text("\(e.label) (\(e.code))").tag(e.code)
            }
        }
    }
}
