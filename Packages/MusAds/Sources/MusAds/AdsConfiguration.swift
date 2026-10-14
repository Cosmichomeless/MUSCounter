import Foundation

/// Identificadores de AdMob que se inyectan al compilar (`ADMOB_APP_ID`, `ADMOB_BANNER_UNIT_ID`).
/// Los reales viven fuera del repositorio (`Config/Secrets.xcconfig`); en Debug y CI se usan los de prueba de Google.
public struct AdsConfiguration: Equatable, Sendable {
    public static let googleTestAppID = "ca-app-pub-3940256099942544~1458002511"
    public static let googleTestBannerUnitID = "ca-app-pub-3940256099942544/2435281174"

    public let appID: String
    public let bannerUnitID: String

    public init(appID: String, bannerUnitID: String) {
        self.appID = appID
        self.bannerUnitID = bannerUnitID
    }

    /// Lee los identificadores del `Info.plist`. Devuelve nil si faltan o no tienen forma de ID de AdMob,
    /// con lo que la app funciona igual, sin anuncios.
    public init?(bundle: Bundle = .main) {
        guard let appID = bundle.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              let unit = bundle.object(forInfoDictionaryKey: "MusAdBannerUnitID") as? String,
              Self.isValid(appID: appID), Self.isValid(unitID: unit)
        else { return nil }
        self.init(appID: appID, bannerUnitID: unit)
    }

    /// `true` si son los identificadores de prueba de Google (nunca deben publicarse así).
    public var usesGoogleTestIdentifiers: Bool {
        appID == Self.googleTestAppID || bannerUnitID == Self.googleTestBannerUnitID
    }

    static func isValid(appID: String) -> Bool {
        matches(appID, #"^ca-app-pub-\d{16}~\d{10}$"#)
    }

    static func isValid(unitID: String) -> Bool {
        matches(unitID, #"^ca-app-pub-\d{16}/\d{10}$"#)
    }

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
