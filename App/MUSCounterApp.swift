import SwiftUI
import MusCore

@main
struct MUSCounterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        Text("MUSCounter")
            .font(.largeTitle.bold())
    }
}
