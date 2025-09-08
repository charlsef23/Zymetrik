import Foundation
import Supabase

extension SupabaseService {
    struct Liker: Identifiable, Decodable, Equatable {
        let id: UUID
        let username: String
        let nombre: String
        let avatar_url: String?
        let liked_at: Date
    }

    func fetchLikers(postID: UUID, limit: Int = 30, before: Date? = nil) async throws -> [Liker] {
        struct Row: Decodable {
            let liked_at: Date
            let perfil: PerfilRow
            struct PerfilRow: Decodable {
                let id: UUID
                let username: String
                let nombre: String
                let avatar_url: String?
            }
        }

        // 1) Construye el builder de FILTRO primero (aquí puedes usar .lt/.gt/.eq)
        var filter = client
            .from("post_likes")
            .select("""
                liked_at,
                perfil:autor_id (
                    id, username, nombre, avatar_url
                )
            """, head: false)
            .eq("post_id", value: postID.uuidString) // filtro base

        if let before {
            // Cursor: likes más antiguos que 'before'
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
            filter = filter.lt("liked_at", value: iso.string(from: before))
        }

        // 2) Luego aplica transformaciones (order/limit) sobre el transform builder
        let transform = filter
            .order("liked_at", ascending: false)
            .limit(limit)

        let res = try await transform.execute()
        let rows = try res.decodedList(to: Row.self)

        return rows.map {
            Liker(
                id: $0.perfil.id,
                username: $0.perfil.username,
                nombre: $0.perfil.nombre,
                avatar_url: $0.perfil.avatar_url,
                liked_at: $0.liked_at
            )
        }
    }
}
