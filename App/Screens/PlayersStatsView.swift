import SwiftUI
import MusCore

/// Textos de las estadísticas. Aparte de la vista para poder probarlos sin pintar nada.
enum StatsText {
    static func percent(_ rate: Double?) -> String {
        guard let rate else { return "–" }
        return "\(Int((rate * 100).rounded())) %"
    }

    static func games(_ count: Int) -> String {
        count == 1 ? "1 partida" : "\(count) partidas"
    }

    static func wins(_ count: Int) -> String {
        count == 1 ? "1 victoria" : "\(count) victorias"
    }
}

/// Estadísticas de cada jugador y de las parejas, calculadas de las partidas terminadas que siguieron a los jugadores.
struct PlayersStatsView: View {
    let model: AppModel
    @State private var playerToDelete: Player?

    var body: some View {
        let stats = model.playerStats
        let names = Dictionary(uniqueKeysWithValues: model.players.map { ($0.id, $0.name) })
        let ranked = model.players.sorted {
            let a = stats[$0.id]?.gamesPlayed ?? 0, b = stats[$1.id]?.gamesPlayed ?? 0
            return (a, $1.name) > (b, $0.name)
        }
        let pairs = model.pairStats.filter { $0.playerIDs.allSatisfy { names[$0] != nil } }

        VStack(alignment: .leading, spacing: Metrics.spacingM) {
            if ranked.isEmpty {
                Text("Escribe los nombres de los cuatro jugadores al empezar una partida y aquí verás las victorias, las vacas y los órdagos de cada uno.")
                    .foregroundStyle(Theme.mutedText)
                    .padding(.top, Metrics.spacingL)
            } else {
                ForEach(ranked) { player in card(player, stats[player.id]) }
                if !pairs.isEmpty {
                    Text("PAREJAS")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.mutedText)
                        .padding(.top, Metrics.spacingS)
                    ForEach(pairs) { pair in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.playerIDs.compactMap { names[$0] }.joined(separator: " y ")).font(.headline)
                            Text("\(StatsText.games(pair.gamesPlayed)) · \(StatsText.wins(pair.gamesWon)) (\(StatsText.percent(pair.winRate)))")
                                .font(.subheadline).foregroundStyle(Theme.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .musCard()
                        .accessibilityElement(children: .combine)
                    }
                }
                Text("Cuentan solo las partidas terminadas con los cuatro jugadores. Todo se guarda en este iPhone.")
                    .font(.footnote).foregroundStyle(Theme.mutedText)
            }
        }
        .confirmationDialog(
            "¿Borrar al jugador?",
            isPresented: Binding(get: { playerToDelete != nil }, set: { if !$0 { playerToDelete = nil } }),
            titleVisibility: .visible,
            presenting: playerToDelete
        ) { player in
            Button("Borrar a \(player.name)", role: .destructive) { model.deletePlayer(player.id) }
            Button("Cancelar", role: .cancel) {}
        } message: { _ in
            Text("Dejará de salir en las estadísticas. Las partidas del historial no cambian.")
        }
    }

    private func card(_ player: Player, _ stats: PlayerStats?) -> some View {
        let played = stats?.gamesPlayed ?? 0
        return HStack(alignment: .top, spacing: Metrics.spacingM) {
            VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                Text(player.name).font(.headline)
                if let stats, played > 0 {
                    Text("\(StatsText.games(played)) · \(StatsText.wins(stats.gamesWon)) (\(StatsText.percent(stats.winRate)))")
                        .font(.subheadline)
                    Text(detail(stats)).font(.footnote).foregroundStyle(Theme.mutedText)
                } else {
                    Text("Sin partidas terminadas").font(.subheadline).foregroundStyle(Theme.mutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button {
                playerToDelete = player
            } label: {
                Image(systemName: "trash").font(.title3)
                    .foregroundStyle(Theme.danger)
                    .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Borrar a \(player.name)")
        }
        .musCard()
    }

    private func detail(_ stats: PlayerStats) -> String {
        var parts = ["Vacas ganadas: \(stats.vacasWon)"]
        if stats.ordagosWon + stats.ordagosLost > 0 {
            parts.append("Órdagos: \(stats.ordagosWon) ganados, \(stats.ordagosLost) perdidos")
        }
        if let best = stats.bestLance { parts.append("Más tantos en \(best.displayName)") }
        return parts.joined(separator: " · ")
    }
}
