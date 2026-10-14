import Foundation

public protocol AppDataStore {
    func load() throws -> AppData
    func save(_ data: AppData) throws
    /// Borra todos los datos locales.
    func deleteAll() throws
}

/// Guarda `AppData` como un único JSON con escritura atómica.
public struct FileAppDataStore: AppDataStore {
    public let fileURL: URL
    private let migrator: SchemaMigrator

    public init(fileURL: URL, migrator: SchemaMigrator = .standard) {
        self.fileURL = fileURL
        self.migrator = migrator
    }

    /// `Application Support/MUSCounter/appdata.json` dentro del sandbox de la app.
    public static func defaultURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return base.appendingPathComponent("MUSCounter", isDirectory: true).appendingPathComponent("appdata.json")
    }

    public func load() throws -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        let raw = try Data(contentsOf: fileURL)
        let migrated = try migrator.migrate(raw)
        do {
            return try Self.makeDecoder().decode(AppData.self, from: migrated)
        } catch {
            throw PersistenceError.corrupted(String(describing: error))
        }
    }

    public func save(_ data: AppData) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.makeEncoder().encode(data).write(to: fileURL, options: .atomic)
    }

    public func deleteAll() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
