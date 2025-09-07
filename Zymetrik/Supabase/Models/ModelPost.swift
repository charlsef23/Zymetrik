import Foundation

struct Comentario: Identifiable, Decodable, Equatable {
    let id: UUID
    let post_id: UUID
    let autor_id: UUID
    let contenido: String
    let creado_en: Date
    let comentario_padre_id: UUID?

    /// Join embebido
    let perfil: Perfil?

    /// Alias plano si la RPC devuelve `username, avatar_url`
    private let username_explicit: String?
    private let avatar_url_explicit: String?

    struct Perfil: Decodable {
        let username: String
        let avatar_url: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, post_id, autor_id, contenido, creado_en, comentario_padre_id, perfil
        case username_explicit = "username"
        case avatar_url_explicit = "avatar_url"
    }

    /// Nombre de usuario para la UI
    var username: String {
        username_explicit ?? perfil?.username ?? "usuario"
    }

    /// URL de avatar (si existe) para la UI
    var avatarURL: URL? {
        if let raw = avatar_url_explicit ?? perfil?.avatar_url {
            return URL(string: raw)
        }
        return nil
    }

    static func == (lhs: Comentario, rhs: Comentario) -> Bool {
        lhs.id == rhs.id
    }
}

struct NuevoComentario: Encodable {
    let post_id: UUID
    let autor_id: UUID
    let contenido: String
    let comentario_padre_id: UUID?
}

struct PostLike: Decodable {
    let post_id: UUID
    let autor_id: UUID
    let liked_at: Date?
}

enum CountOption: String {
    case exact, planned, estimated
}

struct NuevoLike: Encodable {
    let post_id: UUID
    let autor_id: UUID
}
