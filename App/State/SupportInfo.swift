import Foundation

/// Enlaces de privacidad y soporte. Vienen del `Info.plist` (`PRIVACY_POLICY_URL`, `SUPPORT_EMAIL` en los
/// `.xcconfig`); si faltan o no son válidos, la app no los muestra en vez de enseñar un enlace roto.
struct SupportInfo: Equatable {
    let policyURL: URL?
    let supportEmail: String?

    init(policyURL: URL?, supportEmail: String?) {
        self.policyURL = policyURL
        self.supportEmail = supportEmail
    }

    init(bundle: Bundle = .main) {
        self.init(
            policyURL: Self.url(from: bundle.object(forInfoDictionaryKey: "MusPrivacyPolicyURL") as? String),
            supportEmail: Self.email(from: bundle.object(forInfoDictionaryKey: "MusSupportEmail") as? String)
        )
    }

    /// Dirección `mailto:` con asunto, o nil si no hay correo configurado.
    var supportMailURL: URL? {
        guard let supportEmail else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [URLQueryItem(name: "subject", value: "Tanteo Mus: soporte")]
        return components.url
    }

    static func url(from text: String?) -> URL? {
        guard let text = text?.trimmingCharacters(in: .whitespaces),
              let url = URL(string: text), url.scheme == "https", url.host()?.contains(".") == true
        else { return nil }
        return url
    }

    static func email(from text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespaces),
              text.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
        else { return nil }
        return text
    }
}
