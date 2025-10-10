import Foundation
import Supabase

public enum FollowError: Error { case sessionMissing }

public struct FollowersService {
    public static let shared = FollowersService()
    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Session
    private func currentUserID() async throws -> String {
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString
        } catch {
            // Si la sesión caducó, intenta refrescar
            _ = try await client.auth.refreshSession()
            let session = try await client.auth.session
            return session.user.id.uuidString
        }
    }

    // MARK: - Contadores
    public func countFollowers(userID: String) async throws -> Int {
        let r = try await client
            .from("followers")
            .select("follower_id", count: .exact)
            .eq("followed_id", value: userID)
            .execute()
        return r.count ?? 0
    }

    public func countFollowing(userID: String) async throws -> Int {
        let r = try await client
            .from("followers")
            .select("followed_id", count: .exact)
            .eq("follower_id", value: userID)
            .execute()
        return r.count ?? 0
    }

    public func counts(for userID: String) async throws -> (following: Int, followers: Int) {
        async let following = countFollowing(userID: userID)
        async let followers = countFollowers(userID: userID)
        return try await (following, followers)
    }

    // MARK: - Acciones (devuelven contadores actualizados)
    @discardableResult
    public func follow(targetUserID: String) async throws -> (targetFollowers: Int, meFollowing: Int) {
        let me = try await currentUserID()
        guard me != targetUserID else {
            return try await (countFollowers(userID: targetUserID), countFollowing(userID: me))
        }

        // Idempotente: onConflict por PK compuesta
        _ = try await client
            .from("followers")
            .upsert(["follower_id": me, "followed_id": targetUserID],
                    onConflict: "follower_id,followed_id")
            .execute()

        async let f1 = countFollowers(userID: targetUserID)
        async let f2 = countFollowing(userID: me)
        let (targetFollowers, meFollowing) = try await (f1, f2)

        FollowNotification.post(
            followerID: me,
            targetUserID: targetUserID,
            didFollow: true,
            targetFollowers: targetFollowers,
            meFollowing: meFollowing
        )
        return (targetFollowers, meFollowing)
    }

    @discardableResult
    public func unfollow(targetUserID: String) async throws -> (targetFollowers: Int, meFollowing: Int) {
        let me = try await currentUserID()
        guard me != targetUserID else {
            return try await (countFollowers(userID: targetUserID), countFollowing(userID: me))
        }

        _ = try await client
            .from("followers")
            .delete()
            .eq("follower_id", value: me)
            .eq("followed_id", value: targetUserID)
            .execute()

        async let f1 = countFollowers(userID: targetUserID)
        async let f2 = countFollowing(userID: me)
        let (targetFollowers, meFollowing) = try await (f1, f2)

        FollowNotification.post(
            followerID: me,
            targetUserID: targetUserID,
            didFollow: false,
            targetFollowers: targetFollowers,
            meFollowing: meFollowing
        )
        return (targetFollowers, meFollowing)
    }

    // MARK: - Listas (eficientes con joins)
    // Nota: Usa tus nombres reales de FKs:
    //   fk_follower_profile  = followers(follower_id) -> perfil(id)
    //   fk_followed_profile  = followers(followed_id) -> perfil(id)

    public func fetchFollowers(of userID: String, limit: Int = 200, offset: Int = 0) async throws -> [PerfilResumen] {
        // Quiénes SIGUEN a userID
        let resp = try await client
            .from("followers")
            .select("""
                seguidor:perfil!fk_follower_profile ( id, username, nombre, avatar_url )
            """)
            .eq("followed_id", value: userID)
            .order("followed_at", ascending: false)
            .range(from: offset, to: max(offset, offset + limit - 1))
            .execute()

        struct Row: Decodable { let seguidor: PerfilResumen }
        return try resp.decodedList(to: Row.self).map(\.seguidor)
    }

    public func fetchFollowing(of userID: String, limit: Int = 200, offset: Int = 0) async throws -> [PerfilResumen] {
        // A quién SIGUE userID
        let resp = try await client
            .from("followers")
            .select("""
                seguido:perfil!fk_followed_profile ( id, username, nombre, avatar_url )
            """)
            .eq("follower_id", value: userID)
            .order("followed_at", ascending: false)
            .range(from: offset, to: max(offset, offset + limit - 1))
            .execute()

        struct Row: Decodable { let seguido: PerfilResumen }
        return try resp.decodedList(to: Row.self).map(\.seguido)
    }

    // MARK: - Estado
    public func isFollowing(currentUserID: String, targetUserID: String) async throws -> Bool {
        let r = try await client
            .from("followers")
            .select("followed_id", count: .exact)
            .eq("follower_id", value: currentUserID)
            .eq("followed_id", value: targetUserID)
            .limit(1)
            .execute()
        return (r.count ?? 0) > 0
    }

    // Check if target user follows current user (i.e., they follow me)
    public func doesFollowMe(currentUserID: String, targetUserID: String) async throws -> Bool {
        // Returns true if targetUserID follows currentUserID
        let r = try await client
            .from("followers")
            .select("follower_id", count: .exact)
            .eq("follower_id", value: targetUserID)
            .eq("followed_id", value: currentUserID)
            .limit(1)
            .execute()
        return (r.count ?? 0) > 0
    }
}
