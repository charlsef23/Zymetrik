import Foundation
import Supabase

final class DMMessagingService {
    static let shared = DMMessagingService()
    private init() {}

    // Usa el cliente que ya tienes configurado en tu proyecto
    private let client = SupabaseManager.shared.client

    // Placeholder para Realtime (desactivado por compat)
    private var channels: [UUID: Any] = [:]

    // MARK: - Formateadores de fecha robustos
    private static let iso8601NoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return f
    }()

    private static let iso8601Frac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
        return f
    }()

    private static let fallbackFormatters: [DateFormatter] = {
        let f1 = DateFormatter()
        f1.locale = Locale(identifier: "en_US_POSIX")
        f1.dateFormat = "yyyy-MM-dd HH:mm:ssZ"

        let f2 = DateFormatter()
        f2.locale = Locale(identifier: "en_US_POSIX")
        f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        let f3 = DateFormatter()
        f3.locale = Locale(identifier: "en_US_POSIX")
        f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

        return [f1, f2, f3]
    }()

    // MARK: - JSONDecoder robusto (acepta milisegundos/microsegundos)
    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)

            if let dt = Self.iso8601Frac.date(from: s) { return dt }
            if let dt = Self.iso8601NoFrac.date(from: s) { return dt }
            for f in Self.fallbackFormatters {
                if let dt = f.date(from: s) { return dt }
            }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Fecha inválida: \(s)")
        }
        return d
    }()

    // MARK: - Helpers decode (con logging si falla)
    private func decodeList<T: Decodable>(_ data: Data) throws -> [T] {
        do { return try decoder.decode([T].self, from: data) }
        catch {
            print("❌ decodeList error:", error)
            if let s = String(data: data, encoding: .utf8) { print("↪︎ JSON:", s) }
            throw error
        }
    }

    private func decodeObject<T: Decodable>(_ data: Data) throws -> T {
        do { return try decoder.decode(T.self, from: data) }
        catch {
            print("❌ decodeObject error:", error)
            if let s = String(data: data, encoding: .utf8) { print("↪︎ JSON:", s) }
            throw error
        }
    }

    // MARK: - Auth
    func currentUserID() async throws -> UUID {
        let session = try await client.auth.session // lanza si no hay sesión
        return session.user.id
    }

    // MARK: - Param structs para RPCs (Encodable)
    private struct GetOrCreateDMParams: Encodable { let a: String; let b: String }
    private struct GetUserConversationsParams: Encodable { let user_id: String; let lim: Int }
    private struct GetConversationMembersParams: Encodable { let conv_id: String }
    private struct GetPerfilLiteParams: Encodable { let user_id: String }
    private struct SearchPerfilByUsernameParams: Encodable { let q: String; let lim: Int }
    private struct GetDMMessagesParams: Encodable {
        let conv_id: String
        let before_ts: String?
        let page_size: Int
    }
    private struct DMMessageInsert: Encodable {
        let conv_id: String
        let author_id: String
        let body: String
    }

    // MARK: - RPCs

    func getOrCreateDM(with otherUserID: UUID) async throws -> UUID {
        let myID = try await currentUserID()
        let params = GetOrCreateDMParams(a: myID.uuidString, b: otherUserID.uuidString)
        let res = try await client.rpc("get_or_create_dm", params: params).execute()

        let obj = try JSONSerialization.jsonObject(with: res.data) as? [String: Any]
        guard
            let idString = obj?["get_or_create_dm"] as? String,
            let id = UUID(uuidString: idString)
        else {
            throw NSError(domain: "RPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta RPC inválida"])
        }
        return id
    }

    func fetchConversations(limit: Int = 30) async throws -> [DMConversation] {
        let myID = try await currentUserID()
        let params = GetUserConversationsParams(user_id: myID.uuidString, lim: limit)
        let res = try await client.rpc("get_user_conversations", params: params).execute()
        return try decodeList(res.data)
    }

    func fetchMembers(conversationID: UUID) async throws -> [DMMember] {
        let params = GetConversationMembersParams(conv_id: conversationID.uuidString)
        let res = try await client.rpc("get_conversation_members", params: params).execute()
        return try decodeList(res.data)
    }

    func fetchPerfil(id: UUID) async throws -> PerfilLite {
        let params = GetPerfilLiteParams(user_id: id.uuidString)
        let res = try await client.rpc("get_perfil_lite", params: params).execute()
        if let one = try? decodeObject(res.data) as PerfilLite { return one }
        let list: [PerfilLite] = try decodeList(res.data)
        guard let first = list.first else {
            throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])
        }
        return first
    }

    func searchUsers(usernameQuery: String, limit: Int = 20) async throws -> [PerfilLite] {
        let params = SearchPerfilByUsernameParams(q: usernameQuery, lim: limit)
        let res = try await client.rpc("search_perfil_by_username", params: params).execute()
        return try decodeList(res.data)
    }

    func fetchMessages(conversationID: UUID, before: Date? = nil, pageSize: Int = 30) async throws -> [DMMessage] {
        let iso = before.map { ISO8601DateFormatter().string(from: $0) }
        let params = GetDMMessagesParams(conv_id: conversationID.uuidString, before_ts: iso, page_size: pageSize)
        let res = try await client.rpc("get_dm_messages", params: params).execute()
        let desc: [DMMessage] = try decodeList(res.data)
        return desc.sorted { $0.created_at < $1.created_at } // asc para UI de chat
    }

    func sendMessage(conversationID: UUID, text: String) async throws {
        let myID = try await currentUserID()
        let payload = DMMessageInsert(conv_id: conversationID.uuidString, author_id: myID.uuidString, body: text)
        _ = try await client.rpc("send_dm_message", params: payload).execute()
    }

    // MARK: - Realtime placeholders (desactivado para compat)
    func subscribeToConversation(conversationID: UUID, onInsert: @escaping (DMMessage) -> Void) async throws {
        channels[conversationID] = "noop"
    }
    func unsubscribe(conversationID: UUID) async {
        channels.removeValue(forKey: conversationID)
    }
}
