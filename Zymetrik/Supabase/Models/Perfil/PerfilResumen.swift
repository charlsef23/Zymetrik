import Foundation

/// Perfil público mínimo para listas/filas
public struct PerfilResumen: Identifiable, Codable, Hashable, Equatable, Sendable {
    public let id: String
    public let username: String
    public let nombre: String
    public let avatar_url: String?
}
