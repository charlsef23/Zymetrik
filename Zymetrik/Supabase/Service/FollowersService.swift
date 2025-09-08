import Foundation
import Supabase

public enum FollowError: Error { case sessionMissing }

public struct FollowersService {
    public static let shared = FollowersService()
    private var client: SupabaseClient { SupabaseManager.shared.client }

    private func currentUserID() async throws -> String {
        try await client.auth.session.user.id.uuidString
    }

    // MARK: - Fetch IDs
    private func fetchFollowerIDs(of userID: String) async throws -> [String] {
        struct Row: Decodable { let follower_id: String }
        let rows: [Row] = try await client
            .from("followers").select("follower_id")
            .eq("followed_id", value: userID)
            .execute()
            .decodedList(to: Row.self)
        return rows.map(\.follower_id)
    }

    private func fetchFollowingIDs(of userID: String) async throws -> [String] {
        struct Row: Decodable { let followed_id: String }
        let rows: [Row] = try await client
            .from("followers").select("followed_id")
            .eq("follower_id", value: userID)
            .execute()
            .decodedList(to: Row.self)
        return rows.map(\.followed_id)
    }

    // MARK: - Perfiles por IDs
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

    // MARK: - Público
    public func fetchFollowers(of userID: String) async throws -> [PerfilResumen] {
        let ids = try await fetchFollowerIDs(of: userID)
        let perfiles = try await fetchProfiles(ids: ids)
        return perfiles.sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
    }

    public func fetchFollowing(of userID: String) async throws -> [PerfilResumen] {
        let ids = try await fetchFollowingIDs(of: userID)
        let perfiles = try await fetchProfiles(ids: ids)
        return perfiles.sorted { $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending }
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

    // MARK: - Acciones
    @discardableResult
    public func follow(targetUserID: String) async throws -> Bool {
        let me = try await currentUserID()
        guard me != targetUserID else { return false }
        _ = try await client
            .from("followers")
            .upsert(["follower_id": me, "followed_id": targetUserID],
                    onConflict: "follower_id,followed_id")
            .execute()
        return true
    }

    @discardableResult
    public func unfollow(targetUserID: String) async throws -> Bool {
        let me = try await currentUserID()
        guard me != targetUserID else { return false }
        _ = try await client
            .from("followers")
            .delete()
            .eq("follower_id", value: me)
            .eq("followed_id", value: targetUserID)
            .execute()
        return true
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
}
