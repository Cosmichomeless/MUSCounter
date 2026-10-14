import Foundation

/// Enlaces de privacidad y soporte. Vienen del `Info.plist` (`PRIVACY_POLICY_URL`, `SUPPORT_URL` en los
/// `.xcconfig`); si faltan o no son válidos, la app no los muestra en vez de enseñar un enlace roto.
struct SupportInfo: Equatable {
    let policyURL: URL?
    let supportURL: URL?

    init(policyURL: URL?, supportURL: URL?) {
        self.policyURL = policyURL
        self.supportURL = supportURL
    }

    init(bundle: Bundle = .main) {
        self.init(
            policyURL: Self.url(from: bundle.object(forInfoDictionaryKey: "MusPrivacyPolicyURL") as? String),
            supportURL: Self.url(from: bundle.object(forInfoDictionaryKey: "MusSupportURL") as? String)
        )
    }

    static func url(from text: String?) -> URL? {
        guard let text = text?.trimmingCharacters(in: .whitespaces),
              let url = URL(string: text), url.scheme == "https", url.host()?.contains(".") == true
        else { return nil }
        return url
    }
}
