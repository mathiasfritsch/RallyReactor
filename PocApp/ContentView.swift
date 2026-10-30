import SwiftUI

struct ContentView: View {
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("iOS POC works")
                .font(.title)

            Text("Built without owning a Mac")

            Button("Tapped \(taps) times") {
                taps += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
