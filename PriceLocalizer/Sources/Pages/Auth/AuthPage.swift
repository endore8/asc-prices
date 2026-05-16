import SwiftUI

struct AuthPage: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Auth")
                .font(.title2.bold())
            Text("Auth page placeholder.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
