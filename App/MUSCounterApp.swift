import SwiftUI

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
        ComponentGallery()
    }
}
