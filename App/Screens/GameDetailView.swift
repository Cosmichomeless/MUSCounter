import SwiftUI
import Charts
import MusCore

/// Series de la gráfica con nombres que no se repiten aunque los dos equipos se llamen igual.
private func chartNames(_ game: Game) -> PerTeam<String> {
    let first = game.teamNames.first, second = game.teamNames.second
    return first == second ? PerTeam("\(first) (1)", "\(second) (2)") : PerTeam(first, second)
}

/// Evolución del tanteo de una partida, acción a acción. Las líneas se cortan al cerrar cada vaca
/// y las rayas suaves marcan los cambios de mano.
struct ScoreChart: View {
    let game: Game
    var colors: (TeamID) -> Color = Theme.team
    var gridColor: Color = Theme.mutedText

    var body: some View {
        let timeline = ScoreTimeline(game: game)
        let names = chartNames(game)
        Chart {
            ForEach(timeline.points.filter(\.isHandBreak), id: \.step) { point in
                RuleMark(x: .value("Paso", point.step))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(gridColor.opacity(0.18))
            }
            RuleMark(y: .value("Meta", timeline.goal))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(gridColor.opacity(0.6))
            ForEach(TeamID.allCases, id: \.self) { team in
                ForEach(timeline.points, id: \.step) { point in
                    LineMark(
                        x: .value("Paso", point.step),
                        y: .value("Tantos", point.score[team]),
                        series: .value("Línea", "\(team == .first ? 1 : 2)-\(point.vaca)")
                    )
                    .foregroundStyle(by: .value("Equipo", names[team]))
                    .interpolationMethod(.stepEnd)
                }
            }
        }
        .chartForegroundStyleScale([
            names.first: colors(.first),
            names.second: colors(.second),
        ])
        .chartYScale(domain: 0...timeline.goal)
        .chartXAxis(.hidden)
        .chartLegend(position: .bottom, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gráfica de la evolución del tanteo")
        .accessibilityValue(ScoreChartText.summary(game))
    }
}

enum ScoreChartText {
    /// Descripción hablada de la gráfica para VoiceOver.
    static func summary(_ game: Game) -> String {
        let timeline = ScoreTimeline(game: game)
        let anotaciones = max(timeline.points.count - 1, 0)
        return "\(anotaciones) anotaciones. \(HistoryText.score(game)) \(HistoryText.scoreUnit(game)). Meta: \(timeline.goal) tantos."
    }

    /// Tantos sumados por lance y equipo, sin contar los ajustes manuales.
    static func tantos(_ game: Game) -> [(lance: Lance, tantos: PerTeam<Int>)] {
        Lance.allCases.compactMap { lance in
            var total = PerTeam(0, 0)
            for action in game.actions {
                if case let .score(actionLance) = action.kind, actionLance == lance { total[action.team] += action.amount }
            }
            return total.first + total.second > 0 ? (lance, total) : nil
        }
    }
}

/// Resumen de una partida: gráfica, tantos por lance y botón para compartir el resultado como imagen.
struct GameDetailView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Resumen").font(.title.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark").font(.title3.weight(.bold))
                        .frame(width: Metrics.minTapTarget, height: Metrics.minTapTarget)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar resumen")
            }
            .padding(Metrics.spacingL)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacingL) {
                    VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                        Text(HistoryText.score(game)).font(.title3.bold())
                        Text(HistoryText.result(game)).font(.subheadline)
                        Text("\(HistoryText.rules(game)) · \(HistoryText.date(of: game))")
                            .font(.footnote).foregroundStyle(Theme.mutedText)
                    }
                    .accessibilityElement(children: .combine)

                    ScoreChart(game: game)
                        .frame(height: 240)
                        .musCard()

                    lanceTable
                }
                .padding(.horizontal, Metrics.spacingL)
            }

            if let shareImage {
                ShareLink(
                    item: Image(uiImage: shareImage),
                    preview: SharePreview("Resultado de la partida", image: Image(uiImage: shareImage))
                ) {
                    Label("Compartir resultado", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.musPrimary)
                .padding(Metrics.spacingL)
            }
        }
        .foregroundStyle(Theme.text)
        .musScreen()
        .task { shareImage = ShareCard.render(game) }
    }

    @ViewBuilder private var lanceTable: some View {
        let rows = ScoreChartText.tantos(game)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: Metrics.spacingS) {
                Text("TANTOS POR LANCE")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.mutedText)
                HStack {
                    Text("").frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(TeamID.allCases, id: \.self) { team in
                        HStack(spacing: Metrics.spacingXS) {
                            TeamMarker(team: team, size: 12)
                            Text(game.teamNames[team]).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .font(.footnote.weight(.semibold))
                ForEach(rows, id: \.lance) { row in
                    HStack {
                        Text(row.lance.displayName).frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(row.tantos.first)").frame(maxWidth: .infinity)
                        Text("\(row.tantos.second)").frame(maxWidth: .infinity)
                    }
                    .font(.subheadline)
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.lance.displayName): \(game.teamNames.first) \(row.tantos.first), \(game.teamNames.second) \(row.tantos.second)")
                }
            }
            .musCard()
        }
    }
}

/// Tarjeta con el resultado que se comparte como imagen. Colores fijos (tema oscuro) para que salga igual
/// en cualquier iPhone, y sin anuncios.
struct ShareCard: View {
    let game: Game
    private static let palette = Palette.dark

    var body: some View {
        let p = Self.palette
        VStack(alignment: .leading, spacing: 14) {
            Text("Tanteo Mus").font(.footnote.weight(.bold)).foregroundStyle(Color(p.accent))
            Text(HistoryText.result(game)).font(.headline)
            HStack(alignment: .firstTextBaseline) {
                ForEach(TeamID.allCases, id: \.self) { team in
                    VStack(spacing: 2) {
                        Text("\(shownScore(team))")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(Color(p.team(team)))
                        Text(game.teamNames[team]).font(.subheadline).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            ScoreChart(game: game, colors: { Color(p.team($0)) }, gridColor: Color(p.mutedText))
                .frame(height: 160)
            Text("\(HistoryText.rules(game)) · \(HistoryText.date(of: game))")
                .font(.caption).foregroundStyle(Color(p.mutedText))
        }
        .foregroundStyle(Color(p.text))
        .padding(20)
        .frame(width: 360)
        .background(Color(p.background))
        .environment(\.colorScheme, .dark)
    }

    private func shownScore(_ team: TeamID) -> Int {
        game.rules.vacasToWin > 1 ? game.state.vacas[team] : game.state.score[team]
    }

    @MainActor static func render(_ game: Game) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCard(game: game))
        renderer.scale = 3
        return renderer.uiImage
    }
}
