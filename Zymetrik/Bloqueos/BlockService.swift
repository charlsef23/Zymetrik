import Foundation
import Supabase

enum BlockError: Error { case notLoggedIn, invalidTarget }

struct BlockedUser: Decodable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let nombre: String?
    let avatar_url: String?
    var displayName: String { (nombre?.isEmpty == false ? nombre! : username) }
}

final class BlockService {
    static let shared = BlockService()
    private init() {}

    // MARK: - Session
    private func myId() async throws -> String {
        let session = try await SupabaseManager.shared.client.auth.session
        return session.user.id.uuidString
    }

    // MARK: - Listado
    func listBlocked() async throws -> [BlockedUser] {
        let me = try await myId()

        // BlockService.listBlocked()
        let resp = try await SupabaseManager.shared.client
          .from("bloqueos")
          .select("bloqueado:bloqueado_id!left(id, username, nombre, avatar_url)")
          .eq("usuario_id", value: me)
          .order("fecha", ascending: false)
          .execute()

        struct Row: Decodable { let bloqueado: BlockedUser? }
        return try resp.decodedList(to: Row.self).compactMap { $0.bloqueado }
    }
    // MARK: - Acciones directas
    func block(targetUserID: UUID) async throws {
        let me = try await myId()
        struct Row: Encodable { let usuario_id: String; let bloqueado_id: String }
        _ = try await SupabaseManager.shared.client
            .from("bloqueos")
            .upsert(Row(usuario_id: me, bloqueado_id: targetUserID.uuidString),
                    onConflict: "usuario_id,bloqueado_id")
            .execute()
    }

    func block(targetUserID: String) async throws {
        guard let uuid = UUID(uuidString: targetUserID) else { throw BlockError.invalidTarget }
        try await block(targetUserID: uuid)
    }

    func unblock(targetUserID: UUID) async throws {
        let me = try await myId()
        _ = try await SupabaseManager.shared.client
            .from("bloqueos")
            .delete()
            .eq("usuario_id", value: me)
            .eq("bloqueado_id", value: targetUserID.uuidString)
            .execute()
    }

    func unblock(targetUserID: String) async throws {
        guard let uuid = UUID(uuidString: targetUserID) else { throw BlockError.invalidTarget }
        try await unblock(targetUserID: uuid)
    }

    // MARK: - Estado
    func iBlock(targetUserID: UUID) async throws -> Bool {
        let me = try await myId()
        let r = try await SupabaseManager.shared.client
            .from("bloqueos")
            .select("id", count: .exact)
            .eq("usuario_id", value: me)
            .eq("bloqueado_id", value: targetUserID.uuidString)
            .execute()
        return (r.count ?? 0) > 0
    }

    func iBlock(targetUserID: String) async throws -> Bool {
        guard let uuid = UUID(uuidString: targetUserID) else { throw BlockError.invalidTarget }
        return try await iBlock(targetUserID: uuid)
    }

    func blocksMe(targetUserID: UUID) async throws -> Bool {
        let me = try await myId()
        let r = try await SupabaseManager.shared.client
            .from("bloqueos")
            .select("id", count: .exact)
            .eq("usuario_id", value: targetUserID.uuidString)
            .eq("bloqueado_id", value: me)
            .execute()
        return (r.count ?? 0) > 0
    }

    func blocksMe(targetUserID: String) async throws -> Bool {
        guard let uuid = UUID(uuidString: targetUserID) else { throw BlockError.invalidTarget }
        return try await blocksMe(targetUserID: uuid)
    }

    // MARK: - Toggle vía RPC
    /// Requiere: `api_toggle_block(p_target uuid) returns table(status text)`
    @discardableResult
    func toggleBlock(targetUserID: UUID) async throws -> String {
        let response = try await SupabaseManager.shared.client
            .rpc("api_toggle_block", params: ["p_target": targetUserID])
            .execute()
        struct Result: Decodable { let status: String }
        return try response.decoded(to: Result.self).status
    }

    @discardableResult
    func toggleBlock(targetUserID: String) async throws -> String {
        guard let uuid = UUID(uuidString: targetUserID) else { throw BlockError.invalidTarget }
        return try await toggleBlock(targetUserID: uuid)
    }

    // MARK: - Contador (para trailing en Ajustes)
    func countBlocked() async throws -> Int {
        let me = try await myId()
        let resp = try await SupabaseManager.shared.client
            .from("bloqueos")
            .select("id", count: .exact)
            .eq("usuario_id", value: me)
            .execute()
        return resp.count ?? 0
    }
}
