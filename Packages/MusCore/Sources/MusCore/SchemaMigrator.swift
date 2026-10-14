import Foundation

public enum PersistenceError: Error, Equatable {
    /// El fichero lo escribió una versión más reciente de la app.
    case unsupportedSchemaVersion(Int)
    /// El contenido no es un JSON válido o falta un paso de migración.
    case corrupted(String)
}

/// Lleva el JSON guardado hasta la versión de esquema actual aplicando migraciones en orden.
/// `steps[n]` convierte un documento de la versión `n` a la `n + 1`.
public struct SchemaMigrator {
    public typealias Step = ([String: Any]) throws -> [String: Any]

    public let currentVersion: Int
    private let steps: [Int: Step]

    public init(currentVersion: Int, steps: [Int: Step] = [:]) {
        self.currentVersion = currentVersion
        self.steps = steps
    }

    /// Migrador de la app. Cuando se cambie el esquema: subir `currentSchemaVersion` y añadir aquí el paso.
    public static let standard = SchemaMigrator(currentVersion: AppData.currentSchemaVersion)

    public func migrate(_ data: Data) throws -> Data {
        guard var document = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PersistenceError.corrupted("El fichero no es un objeto JSON.")
        }
        var version = document["schemaVersion"] as? Int ?? 0
        if version > currentVersion { throw PersistenceError.unsupportedSchemaVersion(version) }
        if version == currentVersion { return data }

        while version < currentVersion {
            guard let step = steps[version] else {
                throw PersistenceError.corrupted("No hay migración desde la versión \(version).")
            }
            document = try step(document)
            version += 1
            document["schemaVersion"] = version
        }
        return try JSONSerialization.data(withJSONObject: document)
    }
}
