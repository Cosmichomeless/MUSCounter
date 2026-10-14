import SwiftUI
import MusCore

struct HomeView: View {
    let model: AppModel
    @State private var confirmReplace = false
    @State private var pendingDraft: GameSetupDraft?

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .foregroundStyle(Theme.text)
        .safeAreaInset(edge: .bottom, spacing: 0) { AdSlot(placement: .home) }
        .musScreen()
        .confirmationDialog(
            "Ya tienes una partida en curso",
            isPresented: $confirmReplace,
            titleVisibility: .visible
        ) {
            Button("Empezar una nueva", role: .destructive) {
                if let draft = pendingDraft { model.startGame(with: draft) }
                pendingDraft = nil
            }
            Button("Cancelar", role: .cancel) { pendingDraft = nil }
        } message: {
            Text("La partida actual se guardará en el historial como abandonada.")
        }
    }

    /// Vertical: todo apilado. Horizontal: la marca a la izquierda y las acciones a la derecha.
    @ViewBuilder private var content: some View {
        if isLandscape {
            HStack(spacing: Metrics.spacingXL) {
                branding.frame(maxWidth: .infinity)
                VStack(spacing: Metrics.spacingM) {
                    banners
                    actions
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Metrics.spacingL)
        } else {
            VStack(spacing: Metrics.spacingL) {
                Spacer(minLength: Metrics.spacingXL)
                branding
                Spacer(minLength: Metrics.spacingXL)
                banners
                actions
            }
            .padding(Metrics.spacingL)
        }
    }

    private var branding: some View {
        VStack(spacing: Metrics.spacingM) {
            Image(systemName: "suit.club.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
                .frame(width: 96, height: 96)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.accent, lineWidth: 3))
                .accessibilityHidden(true)
            Text("Marcador de mus")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Sin cuenta, sin anuncios, sin conexión.")
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder private var banners: some View {
        if let message = model.errorMessage {
            ErrorBanner(message: message)
        }
        if let game = model.game, game.isInProgress {
            resumeCard(game)
        }
    }

    private var actions: some View {
        VStack(spacing: Metrics.spacingM) {
            Button("Nueva partida") { requestStart(GameSetupDraft(preferences: model.preferences)) }
                .buttonStyle(.musPrimary)
            Button("Opciones de la partida") { model.openSetup() }
                .buttonStyle(.musSecondary)
            HStack(spacing: Metrics.spacingM) {
                Button("Historial") { model.openHistory() }
                    .buttonStyle(.musSecondary)
                Button("Ajustes") { model.openSettings() }
                    .buttonStyle(.musSecondary)
            }
        }
    }

    private func resumeCard(_ game: Game) -> some View {
        HStack(spacing: Metrics.spacingM) {
            VStack(alignment: .leading, spacing: Metrics.spacingXS) {
                Text("Partida en curso").font(.headline)
                Text("\(game.teamNames.first) \(game.state.score.first) – \(game.state.score.second) \(game.teamNames.second)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer(minLength: 0)
            Button("Continuar") { model.resumeGame() }
                .buttonStyle(.musPrimary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .musCard()
        .accessibilityElement(children: .contain)
    }

    private func requestStart(_ draft: GameSetupDraft) {
        if model.hasGameInProgress {
            pendingDraft = draft
            confirmReplace = true
        } else {
            model.startGame(with: draft)
        }
    }
}
