// DMMessagingService.swift
import Foundation
import Supabase

final class DMMessagingService {
    static let shared = DMMessagingService()
    private init() {}

    let client = SupabaseManager.shared.client

    // Realtime V2
    private var channels: [UUID: RealtimeChannelV2] = [:]

    // MARK: - Decoder robusto
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
        f1.locale = .init(identifier: "en_US_POSIX")
        f1.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let f2 = DateFormatter()
        f2.locale = .init(identifier: "en_US_POSIX")
        f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let f3 = DateFormatter()
        f3.locale = .init(identifier: "en_US_POSIX")
        f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return [f1, f2, f3]
    }()
    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let dt = Self.iso8601Frac.date(from: s) { return dt }
            if let dt = Self.iso8601NoFrac.date(from: s) { return dt }
            for f in Self.fallbackFormatters { if let dt = f.date(from: s) { return dt } }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Fecha inválida: \(s)")
        }
        return d
    }()
    private func decodeList<T: Decodable>(_ data: Data) throws -> [T] { try decoder.decode([T].self, from: data) }
    private func decodeObject<T: Decodable>(_ data: Data) throws -> T { try decoder.decode(T.self, from: data) }

    // MARK: - Auth
    func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }

    // MARK: - RPC Params
    private struct GetOrCreateDMParams: Encodable { let a: String; let b: String }
    private struct GetUserConversationsParams: Encodable { let user_id: String; let lim: Int }
    private struct GetConversationMembersParams: Encodable { let conv_id: String }
    private struct GetPerfilLiteParams: Encodable { let user_id: String }
    private struct GetDMMessagesParams: Encodable {
        let conv_id: String
        let before_ts: String?
        let after_ts: String?
        let page_size: Int
    }
    private struct SendDMParams: Encodable {
        let conv_id: String
        let body: String
        let client_tag: String?
    }
    private struct EditParams: Encodable { let msg_id: String; let new_body: String }
    private struct HideParams: Encodable { let conv_id: String; let msg_id: String }
    private struct DeleteAllParams: Encodable { let msg_id: String }

    // MARK: - RPCs
    func getOrCreateDM(with other: UUID) async throws -> UUID {
        let my = try await currentUserID()
        let p = GetOrCreateDMParams(a: my.uuidString, b: other.uuidString)
        let res = try await client.rpc("get_or_create_dm", params: p).execute()

        if let dict = try? JSONSerialization.jsonObject(with: res.data) as? [String: Any] {
            if let s = dict["get_or_create_dm"] as? String, let id = UUID(uuidString: s) { return id }
            if let s = dict["id"] as? String, let id = UUID(uuidString: s) { return id }
            if let zero = dict["0"] as? [String: Any], let s = zero["id"] as? String, let id = UUID(uuidString: s) { return id }
        }
        if let s = try? JSONDecoder().decode(String.self, from: res.data), let id = UUID(uuidString: s) { return id }
        if let arr = try? JSONDecoder().decode([String].self, from: res.data), let s = arr.first, let id = UUID(uuidString: s) { return id }
        if let raw = String(data: res.data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
           let id = UUID(uuidString: raw) { return id }

        throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Respuesta RPC inválida al crear/obtener DM"])
    }

    func fetchConversations(limit: Int = 30) async throws -> [DMConversation] {
        let my = try await currentUserID()
        let p = GetUserConversationsParams(user_id: my.uuidString, lim: limit)
        let res = try await client.rpc("get_user_conversations", params: p).execute()
        return try decodeList(res.data)
    }

    func fetchMembers(conversationID: UUID) async throws -> [DMMember] {
        let p = GetConversationMembersParams(conv_id: conversationID.uuidString)
        let res = try await client.rpc("get_conversation_members", params: p).execute()
        return try decodeList(res.data)
    }

    func fetchPerfil(id: UUID) async throws -> PerfilLite {
        let p = GetPerfilLiteParams(user_id: id.uuidString)
        let res = try await client.rpc("get_perfil_lite", params: p).execute()
        if let one: PerfilLite = try? decodeObject(res.data) { return one }
        let list: [PerfilLite] = try decodeList(res.data)
        guard let first = list.first else {
            throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])
        }
        return first
    }

    func fetchMessages(conversationID: UUID, before: Date? = nil, after: Date? = nil, pageSize: Int = 50) async throws -> [DMMessage] {
        let iso = ISO8601DateFormatter()
        let p = GetDMMessagesParams(
            conv_id: conversationID.uuidString,
            before_ts: before.map { iso.string(from: $0) },
            after_ts:  after.map { iso.string(from: $0) },
            page_size: pageSize
        )
        let res = try await client.rpc("get_dm_messages", params: p).execute()
        return try decodeList(res.data) // asc
    }

    func sendMessage(conversationID: UUID, text: String, clientTag: String) async throws -> DMMessage {
        let payload = SendDMParams(conv_id: conversationID.uuidString, body: text, client_tag: clientTag)
        let res = try await client.rpc("send_dm_message", params: payload).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func setTyping(conversationID: UUID, typing: Bool) async {
        struct P: Encodable { let conv_id: String; let typing: Bool }
        _ = try? await client.rpc("set_dm_typing", params: P(conv_id: conversationID.uuidString, typing: typing)).execute()
    }

    func markRead(conversationID: UUID) async {
        struct P: Encodable { let conv_id: String }
        _ = try? await client.rpc("mark_dm_read", params: P(conv_id: conversationID.uuidString)).execute()
    }

    func editMessage(messageID: UUID, newText: String) async throws -> DMMessage {
        let res = try await client.rpc("edit_dm_message", params: EditParams(msg_id: messageID.uuidString, new_body: newText)).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func deleteMessageForAll(messageID: UUID) async throws -> DMMessage {
        let res = try await client.rpc("delete_dm_message_for_all", params: DeleteAllParams(msg_id: messageID.uuidString)).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func hideMessageForMe(conversationID: UUID, messageID: UUID) async {
        _ = try? await client.rpc("hide_dm_message_for_me", params: HideParams(conv_id: conversationID.uuidString, msg_id: messageID.uuidString)).execute()
    }

    // MARK: - Realtime V2

    struct RealtimeHandlers {
        var onInserted: ((DMMessage) -> Void)?
        var onUpdated:  ((DMMessage) -> Void)?
        var onDeletedGlobal: ((UUID) -> Void)?
        var onTypingChanged: ((UUID, Bool) -> Void)?
        var onMembersUpdated: (([DMMember]) -> Void)?
    }

    /// Suscribe a cambios de `dm_messages` y `dm_members` para una conversación.
    @discardableResult
    func subscribe(conversationID: UUID, handlers: RealtimeHandlers) async -> RealtimeChannelV2 {
        // Desuscribe si ya existe
        await unsubscribe(conversationID: conversationID)

        // Crea canal
        let channel = client.realtimeV2.channel("dm:\(conversationID.uuidString)")
        channels[conversationID] = channel

        // Filtro PostgREST
        let filter = "conversation_id=eq.\(conversationID.uuidString)"

        // INSERTS: dm_messages
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "dm_messages",
            filter: filter
        ) { [weak self] change in
            guard let self else { return }
            let rec = change.record // [String: AnyJSON]
            if let data = try? JSONEncoder().encode(rec),
               let msg  = try? self.decoder.decode(DMMessage.self, from: data) {
                handlers.onInserted?(msg)
            }
        }

        // UPDATES: dm_messages (editado / delete_for_all)
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "dm_messages",
            filter: filter
        ) { [weak self] change in
            guard let self else { return }
            let rec = change.record
            if let data = try? JSONEncoder().encode(rec),
               let msg  = try? self.decoder.decode(DMMessage.self, from: data) {
                if msg.deleted_for_all_at != nil {
                    handlers.onDeletedGlobal?(msg.id)
                } else {
                    handlers.onUpdated?(msg)
                }
            }
        }

        // UPDATES: dm_members (typing / last_read_at)
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "dm_members",
            filter: filter
        ) { [weak self] _ in
            guard let self else { return }
            // Envolver trabajo async en Task para que el callback siga siendo sync
            Task {
                if let mems = try? await self.fetchMembers(conversationID: conversationID) {
                    // emitir cambios en main si tu UI lo requiere:
                    handlers.onMembersUpdated?(mems)
                    if let typingUser = mems.first(where: { $0.is_typing == true })?.autor_id {
                        handlers.onTypingChanged?(typingUser, true)
                    } else if let other = mems.first?.autor_id {
                        handlers.onTypingChanged?(other, false)
                    }
                }
            }
        }

        // Activar canal (async)
        await channel.subscribe()

        return channel
    }

    func unsubscribe(conversationID: UUID) async {
        if let ch = channels[conversationID] {
            await ch.unsubscribe()
            channels.removeValue(forKey: conversationID)
        }
    }
    
    // DMMessagingService.swift
    func fetchLastMessage(conversationID: UUID) async throws -> DMMessage? {
        struct P: Encodable { let conv_id: String }
        let res = try await client.rpc("get_last_dm_message", params: P(conv_id: conversationID.uuidString)).execute()
        let list: [DMMessage] = try decodeList(res.data)
        return list.first
    }
}
