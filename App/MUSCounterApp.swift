import MusAds
import SwiftUI

@main
struct MUSCounterApp: App {
    @State private var model = AppModel.live()
    @State private var ads = AdsController.live()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .environment(ads)
                .task { await ads.start() }
        }
    }
}

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        screen.preferredColorScheme(model.preferences.theme.colorScheme)
    }

    @ViewBuilder private var screen: some View {
        switch model.screen {
        case .home: HomeView(model: model)
        case .setup: SetupView(model: model)
        case .game: GameView(model: model)
        case .result: ResultView(model: model)
        case .history: HistoryView(model: model)
        case .settings: SettingsView(model: model)
        }
    }
}
