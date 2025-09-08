import Foundation
import Supabase

public enum FollowError: Error { case sessionMissing }

public struct FollowersService {
    public static let shared = FollowersService()
    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func currentUserID() async throws -> String {
        try await client.auth.session.user.id.uuidString
    }

    // MARK: - Contadores
    public func countFollowers(userID: String) async throws -> Int {
        let r = try await client
            .from("followers").select("follower_id", count: .exact)
            .eq("followed_id", value: userID)
            .execute()
        return r.count ?? 0
    }

    public func countFollowing(userID: String) async throws -> Int {
        let r = try await client
            .from("followers").select("followed_id", count: .exact)
            .eq("follower_id", value: userID)
            .execute()
        return r.count ?? 0
    }

    // MARK: - Acciones (devuelven contadores actualizados)
    @discardableResult
    public func follow(targetUserID: String) async throws -> (targetFollowers: Int, meFollowing: Int) {
        let me = try await currentUserID()
        guard me != targetUserID else {
            return (try await countFollowers(userID: targetUserID),
                    try await countFollowing(userID: me))
        }

        // Idempotente
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
            return (try await countFollowers(userID: targetUserID),
                    try await countFollowing(userID: me))
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

    // MARK: - Listas
    public func fetchFollowers(of userID: String) async throws -> [PerfilResumen] {
        struct Row: Decodable { let follower_id: String }
        let rows: [Row] = try await client
            .from("followers").select("follower_id")
            .eq("followed_id", value: userID)
            .execute()
            .decodedList(to: Row.self)
        let ids = rows.map(\.follower_id)
        return try await fetchProfiles(ids: ids)
            .sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    public func fetchFollowing(of userID: String) async throws -> [PerfilResumen] {
        struct Row: Decodable { let followed_id: String }
        let rows: [Row] = try await client
            .from("followers").select("followed_id")
            .eq("follower_id", value: userID)
            .execute()
            .decodedList(to: Row.self)
        let ids = rows.map(\.followed_id)
        return try await fetchProfiles(ids: ids)
            .sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    // MARK: - Aux
    private func fetchProfiles(ids: [String]) async throws -> [PerfilResumen] {
        guard !ids.isEmpty else { return [] }
        struct P: Decodable { let id, username, nombre: String; let avatar_url: String? }
        let rows: [P] = try await client
            .from("perfil")
            .select("id,username,nombre,avatar_url")
            .in("id", values: ids)
            .execute()
            .decodedList(to: P.self)
        return rows.map { PerfilResumen(id: $0.id, username: $0.username, nombre: $0.nombre, avatar_url: $0.avatar_url) }
    }

    public func isFollowing(currentUserID: String, targetUserID: String) async throws -> Bool {
        struct Row: Decodable { let follower_id: String }
        let rows: [Row] = try await client
            .from("followers").select("follower_id")
            .eq("follower_id", value: currentUserID)
            .eq("followed_id", value: targetUserID)
            .limit(1)
            .execute()
            .decodedList(to: Row.self)
        return !rows.isEmpty
    }
}
