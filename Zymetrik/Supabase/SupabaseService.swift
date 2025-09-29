import Foundation
import Supabase

// MARK: - Servicio principal

struct SupabaseService {
    static let shared = SupabaseService()
    let client = SupabaseManager.shared.client

    // Feed de posts (desde la vista posts_enriched)
    func fetchPosts(id: UUID? = nil, limit: Int = 20) async throws -> [Post] {
        var q = client
            .from("posts_enriched")
            .select("id, fecha, autor_id, username, avatar_url, contenido, likes_count, comments_count")

        if let id { q = q.eq("id", value: id.uuidString) }

        let res = try await q
            .order("fecha", ascending: false)
            .limit(limit)
            .execute()
        return try res.decodedList(to: Post.self)
    }
}

// MARK: - Eliminar post

extension SupabaseService {
    func eliminarPost(postID: UUID) async throws {
        _ = try await client
            .from("posts")
            .delete()
            .eq("id", value: postID.uuidString)
            .execute()
    }
}

// MARK: - Post Meta (liked/saved/contadores via RPC)

extension SupabaseService {
    struct PostMetaResponse: Decodable {
        let liked: Bool
        let saved: Bool
        let likes_count: Int
        let comments_count: Int
    }

    /// Carga la metadata de un post para el usuario actual (liked/saved + contadores).
    func fetchPostMeta(postID: UUID) async throws -> PostMetaResponse {
        struct P: Encodable { let p_post: UUID }
        let res = try await client
            .rpc("api_get_post_meta", params: P(p_post: postID))
            .single()
            .execute()
        return try res.decoded(to: PostMetaResponse.self)
    }
}

// MARK: - Likes (por usuario, usando RPC api_toggle_like)

extension SupabaseService {

    struct ToggleLikeResult: Decodable {
        let liked: Bool
        let likes_count: Int
    }

    /// Llama a la RPC api_toggle_like. Si `like` es nil, hace toggle.
    func toggleLikeRPC(postID: UUID, like: Bool?) async throws -> ToggleLikeResult {
        struct P: Encodable {
            let p_post: UUID
            let p_like: Bool?
        }
        let res = try await client
            .rpc("api_toggle_like", params: P(p_post: postID, p_like: like))
            .single()
            .execute()
        return try res.decoded(to: ToggleLikeResult.self)
    }

    /// Compatibilidad: setLike ahora delega en la RPC (no toca tabla directamente).
    func setLike(postID: UUID, like: Bool) async throws {
        _ = try await toggleLikeRPC(postID: postID, like: like)
    }

    /// ¿El usuario actual ha dado like a este post?
    func didLike(postID: UUID) async throws -> Bool {
        let userId = try await client.auth.session.user.id
        struct Row: Decodable { let post_id: UUID }
        let rows: [Row] = try await client
            .from("post_likes")
            .select("post_id", head: false)
            .eq("post_id", value: postID.uuidString)
            .eq("autor_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .decodedList(to: Row.self)
        return !rows.isEmpty
    }

    /// Conteo de likes: usa posts.likes_count (mantenido por triggers)
    func countLikes(postID: UUID) async throws -> Int {
        struct R: Decodable { let likes_count: Int }
        let r: R = try await client
            .from("posts")
            .select("likes_count")
            .eq("id", value: postID.uuidString)
            .single()
            .execute()
            .decoded(to: R.self)
        return r.likes_count
    }
}

// MARK: - Guardados

extension SupabaseService {
    func didSave(postID: UUID) async throws -> Bool {
        let userId = try await client.auth.session.user.id
        struct Row: Decodable { let post_id: UUID }
        let rows: [Row] = try await client
            .from("post_guardados")
            .select("post_id", head: false)
            .eq("post_id", value: postID.uuidString)
            .eq("autor_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .decodedList(to: Row.self)
        return !rows.isEmpty
    }

    func setSaved(postID: UUID, saved: Bool) async throws {
        let userId = try await client.auth.session.user.id

        if saved {
            _ = try await client
                .from("post_guardados")
                .upsert([
                    "post_id": postID.uuidString,
                    "autor_id": userId.uuidString
                ], onConflict: "post_id,autor_id")
                .execute()
        } else {
            _ = try await client
                .from("post_guardados")
                .delete()
                .eq("post_id", value: postID.uuidString)
                .eq("autor_id", value: userId.uuidString)
                .execute()
        }
    }

    @discardableResult
    func toggleSaved(postID: UUID, currentlySaved: Bool) async throws -> Bool {
        try await setSaved(postID: postID, saved: !currentlySaved)
        return !currentlySaved
    }

    /// Devuelve los posts guardados por el usuario actual.
    func fetchSavedPosts() async throws -> [Post] {
        let userId = try await client.auth.session.user.id

        let res = try await client
            .from("post_guardados")
            .select("""
                post_id,
                posts (
                    id, fecha, autor_id, avatar_url, username, contenido
                )
            """, head: false)
            .eq("autor_id", value: userId.uuidString)
            .execute()

        struct SavedRow: Decodable {
            let post_id: UUID
            let posts: Post
        }

        let rows = try res.decodedList(to: SavedRow.self)
        return rows
            .map { $0.posts }
            .sorted { $0.fecha > $1.fecha }
    }
}

// MARK: - Modelos base

struct Post: Identifiable, Decodable {
    let id: UUID
    let fecha: Date
    let autor_id: UUID
    let avatar_url: String?
    let username: String
    let contenido: [EjercicioPostContenido]
}

struct Perfil: Identifiable, Codable, Equatable {
    let id: UUID
    let username: String
    let nombre: String
    let avatar_url: String?
}

// MARK: - Decoder flexible

enum _SupabaseDecoders {
    static let flexible: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
            if let d = isoFrac.date(from: raw) { return d }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
            if let d = iso.date(from: raw) { return d }

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd HH:mm:ssXXXXX",
                "yyyy-MM-dd"
            ]
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.calendar = Calendar(identifier: .iso8601)

            for f in formats {
                df.dateFormat = f
                if let d = df.date(from: raw) { return d }
            }

            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Unsupported date format: \(raw)")
        }
        return decoder
    }()
}

extension PostgrestResponse {
    func decoded<U: Decodable>(to type: U.Type) throws -> U {
        try _SupabaseDecoders.flexible.decode(U.self, from: self.data)
    }

    func decodedList<U: Decodable>(to type: U.Type) throws -> [U] {
        try _SupabaseDecoders.flexible.decode([U].self, from: self.data)
    }
}

// MARK: - Utilidades fecha

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let now = Date()
        let interval = self.timeIntervalSince(now)
        if abs(interval) < 1 {
            // Fuerza a empezar en 1s en lugar de "ahora"
            return formatter.localizedString(fromTimeInterval: interval >= 0 ? 1 : -1)
        }
        return formatter.localizedString(for: self, relativeTo: now)
    }
}

func dateAtStartOfDayISO8601(_ d: Date) -> Date {
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    return cal.startOfDay(for: d)
}
