import SwiftUI

@main
struct MUSCounterApp: App {
    @State private var model = AppModel.live()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        switch model.screen {
        case .home: HomeView(model: model)
        case .setup: SetupView(model: model)
        case .game: GameView(model: model)
        }
    }
}
