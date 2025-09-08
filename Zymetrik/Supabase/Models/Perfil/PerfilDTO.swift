import Foundation

public struct PerfilDTO: Decodable {
    public let id: String
    public let nombre: String?
    public let username: String?
    public let presentacion: String?
    public let enlaces: String?
    public let avatar_url: String?
}
