import Foundation
import GoogleMobileAds
import Observation
import UIKit
import UserMessagingPlatform

/// Punto único de entrada a los anuncios: consentimiento (Google UMP, RGPD/TCF) y arranque del SDK.
///
/// Reglas de diseño:
/// - Sin configuración, sin consentimiento o ante cualquier fallo, `canShowAds` es `false` y la app sigue igual.
/// - Nada aquí toca la partida: el marcador no importa este módulo.
@MainActor
@Observable
public final class AdsController {
    public let configuration: AdsConfiguration?

    /// `true` cuando el consentimiento permite pedir anuncios y el SDK está arrancado.
    public private(set) var canShowAds = false
    /// `true` cuando hay que ofrecer al usuario la revisión de su consentimiento (p. ej. en el EEE).
    public private(set) var privacyOptionsRequired = false

    private var started = false

    public init(configuration: AdsConfiguration?) {
        self.configuration = configuration
    }

    /// Controlador sin anuncios: pruebas, vistas previas y compilaciones sin identificadores.
    public static func disabled() -> AdsController { AdsController(configuration: nil) }

    public var isEnabled: Bool { configuration != nil }

    /// Recoge el consentimiento y, si procede, arranca el SDK. Idempotente y sin errores hacia fuera.
    public func start() async {
        guard isEnabled, !started else { return }
        started = true

        await updateConsentInformation()
        await presentConsentFormIfRequired()
        refreshConsentState()
        await startSDKIfAllowed()
    }

    /// Reabre el formulario de opciones de privacidad (Ajustes → revisar consentimiento).
    public func presentPrivacyOptions() async {
        guard isEnabled else { return }
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            ConsentForm.presentPrivacyOptionsForm(from: Self.topViewController()) { _ in done.resume() }
        }
        refreshConsentState()
        await startSDKIfAllowed()
    }

    // MARK: - Consentimiento

    private func updateConsentInformation() async {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in done.resume() }
        }
    }

    private func presentConsentFormIfRequired() async {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            ConsentForm.loadAndPresentIfRequired(from: Self.topViewController()) { _ in done.resume() }
        }
    }

    private func refreshConsentState() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startSDKIfAllowed() async {
        guard ConsentInformation.shared.canRequestAds else {
            canShowAds = false
            return
        }
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            MobileAds.shared.start { _ in done.resume() }
        }
        canShowAds = true
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
