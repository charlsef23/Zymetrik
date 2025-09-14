import Foundation
import Supabase

extension SupabaseService {
    struct PostMeta: Decodable {
        let liked: Bool
        let saved: Bool
        let likes_count: Int
    }

    /// Devuelve liked/saved/likes_count en una sola llamada (RPC `api_post_meta`).
    /// Si la RPC no está aún disponible, hace fallback a las funciones existentes.
    func fetchPostMeta(postID: UUID) async throws -> PostMeta {
        struct P: Encodable { let p_post: UUID }

        do {
            let res = try await client
                .rpc("api_post_meta", params: P(p_post: postID))
                .single()
                .execute()
            return try res.decoded(to: PostMeta.self)

        } catch {
            async let liked: Bool = (try? await didLike(postID: postID)) ?? false
            async let saved: Bool = (try? await didSave(postID: postID)) ?? false
            async let count: Int  = (try? await countLikes(postID: postID)) ?? 0
            let (l, s, c) = await (liked, saved, count)
            return PostMeta(liked: l, saved: s, likes_count: c)
        }
    }
}
