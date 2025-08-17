import SwiftUI

struct Comentario: Identifiable, Decodable {
    let id: UUID
    let post_id: UUID
    let autor_id: UUID
    let contenido: String
    let creado_en: Date
    let comentario_padre_id: UUID?
    let perfil: Perfil?

    struct Perfil: Decodable {
        let username: String
    }

    var username: String {
        perfil?.username ?? "usuario"
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
    case exact
    case planned
    case estimated
}

struct NuevoLike: Encodable {
    let post_id: UUID
    let autor_id: UUID
}
