import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "eye")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Blinkly")
                .font(.largeTitle)
                .fontWeight(.medium)
            Text("Your eye health companion")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

#Preview {
    ContentView()
}
