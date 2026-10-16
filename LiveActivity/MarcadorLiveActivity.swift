import ActivityKit
import MusCore
import SwiftUI
import WidgetKit

@main
struct MUSCounterLiveActivityBundle: WidgetBundle {
    var body: some Widget { MarcadorLiveActivity() }
}

/// Marcador de la partida en la pantalla de bloqueo y la Isla Dinámica. Colores fijos del tema oscuro.
struct MarcadorLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MarcadorActivityAttributes.self) { context in
            LockScreenMarcador(names: context.attributes.teamNames, state: context.state)
                .padding(16)
                .activityBackgroundTint(Color(Palette.dark.background))
                .activitySystemActionForegroundColor(Color(Palette.dark.text))
        } dynamicIsland: { context in
            let names = context.attributes.teamNames
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TeamScore(name: names[0], score: state.score[0], vacas: state.vacas[0], team: .first, state: state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TeamScore(name: names[1], score: state.score[1], vacas: state.vacas[1], team: .second, state: state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let mano = state.mano {
                        Label("Mano: \(mano)", systemImage: "hand.point.up.left.fill").font(.footnote)
                    }
                }
            } compactLeading: {
                Text("\(state.score[0])").foregroundStyle(Color(Palette.dark.team(.first))).monospacedDigit()
            } compactTrailing: {
                Text("\(state.score[1])").foregroundStyle(Color(Palette.dark.team(.second))).monospacedDigit()
            } minimal: {
                Text("\(state.score[0])-\(state.score[1])").font(.caption2).monospacedDigit()
            }
        }
    }
}

private extension Color {
    init(_ rgb: HexColor) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: 1)
    }
}

private struct TeamScore: View {
    let name: String
    let score: Int
    let vacas: Int
    let team: TeamID
    let state: MarcadorActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 2) {
            Text(name).font(.caption).lineLimit(1)
            Text("\(score)")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(Palette.dark.team(team)))
            if state.vacasToWin > 1 {
                Text("Vacas: \(vacas)").font(.caption2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(score) tantos" + (state.vacasToWin > 1 ? ", \(vacas) vacas" : ""))
    }
}

private struct LockScreenMarcador: View {
    let names: [String]
    let state: MarcadorActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TeamScore(name: names[0], score: state.score[0], vacas: state.vacas[0], team: .first, state: state)
                    .frame(maxWidth: .infinity)
                Text("a \(state.goal)").font(.footnote).foregroundStyle(Color(Palette.dark.mutedText))
                TeamScore(name: names[1], score: state.score[1], vacas: state.vacas[1], team: .second, state: state)
                    .frame(maxWidth: .infinity)
            }
            if let mano = state.mano {
                Label("Mano: \(mano)", systemImage: "hand.point.up.left.fill")
                    .font(.footnote)
                    .foregroundStyle(Color(Palette.dark.mutedText))
            }
        }
        .foregroundStyle(Color(Palette.dark.text))
    }
}
