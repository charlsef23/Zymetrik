import Foundation
import Supabase

// MARK: - Servicio de Mensajería (DM)

final class DMMessagingService {
    static let shared = DMMessagingService()
    private init() {}

    let client = SupabaseManager.shared.client

    // Realtime V2 (por conversación)
    private var channels: [UUID: RealtimeChannelV2] = [:]
    private var subscribing: Set<UUID> = []

    // Realtime para Inbox (preview/orden)
    private var inboxChannels: [UUID: RealtimeChannelV2] = [:]

    // MARK: - Robust decoder fechas
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
        let f1 = DateFormatter(); f1.locale = .init(identifier: "en_US_POSIX"); f1.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let f2 = DateFormatter(); f2.locale = .init(identifier: "en_US_POSIX"); f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let f3 = DateFormatter(); f3.locale = .init(identifier: "en_US_POSIX"); f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return [f1, f2, f3]
    }()
    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
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

    private func log(_ items: Any...) {
        #if DEBUG
        print("[DM-RT]", items.map { "\($0)" }.joined(separator: " "))
        #endif
    }

    // MARK: - Auth
    func currentUserID() async throws -> UUID {
        let session = try await client.auth.session
        return session.user.id
    }

    // MARK: - RPC Params
    private struct GetOrCreateDMParams: Encodable { let a: UUID; let b: UUID }
    private struct GetUserConversationsParams: Encodable { let user_id: UUID; let lim: Int }
    private struct GetConversationMembersParams: Encodable { let conv_id: UUID }
    private struct GetPerfilLiteParams: Encodable { let user_id: UUID }
    private struct GetDMMessagesParams: Encodable { let conv_id: UUID; let before_ts: String?; let after_ts: String?; let page_size: Int }
    private struct SendDMParams: Encodable { let conv_id: UUID; let body: String; let client_tag: String? }
    private struct EditParams: Encodable { let msg_id: UUID; let new_body: String }
    private struct HideParams: Encodable { let conv_id: UUID; let msg_id: UUID }
    private struct DeleteAllParams: Encodable { let msg_id: UUID }

    // MARK: - RPCs
    func getOrCreateDM(with other: UUID) async throws -> UUID {
        let my = try await currentUserID()
        let p = GetOrCreateDMParams(a: my, b: other)
        let res = try await client.rpc("get_or_create_dm", params: p).execute()

        // Manejo flexible de respuestas
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
        let p = GetUserConversationsParams(user_id: my, lim: limit)
        let res = try await client.rpc("get_user_conversations", params: p).execute()
        return try decodeList(res.data)
    }

    func fetchMembers(conversationID: UUID) async throws -> [DMMember] {
        let p = GetConversationMembersParams(conv_id: conversationID)
        let res = try await client.rpc("get_conversation_members", params: p).execute()
        return try decodeList(res.data)
    }

    func fetchPerfil(id: UUID) async throws -> PerfilLite {
        let p = GetPerfilLiteParams(user_id: id)
        let res = try await client.rpc("get_perfil_lite", params: p).execute()
        if let one: PerfilLite = try? decodeObject(res.data) { return one }
        let list: [PerfilLite] = try decodeList(res.data)
        if let first = list.first { return first }
        throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])
    }

    func fetchMessages(conversationID: UUID, before: Date? = nil, after: Date? = nil, pageSize: Int = 50) async throws -> [DMMessage] {
        let iso = ISO8601DateFormatter()
        let p = GetDMMessagesParams(
            conv_id: conversationID,
            before_ts: before.map { iso.string(from: $0) },
            after_ts:  after.map { iso.string(from: $0) },
            page_size: pageSize
        )
        let res = try await client.rpc("get_dm_messages", params: p).execute()
        return try decodeList(res.data)
    }

    func fetchLastMessage(conversationID: UUID) async throws -> DMMessage? {
        struct P: Encodable { let conv_id: UUID }
        let res = try await client.rpc("get_last_dm_message", params: P(conv_id: conversationID)).execute()
        let list: [DMMessage] = try decodeList(res.data)
        return list.first
    }

    func sendMessage(conversationID: UUID, text: String, clientTag: String) async throws -> DMMessage {
        let payload = SendDMParams(conv_id: conversationID, body: text, client_tag: clientTag)
        let res = try await client.rpc("send_dm_message", params: payload).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func setTyping(conversationID: UUID, typing: Bool) async {
        struct P: Encodable { let conv_id: UUID; let typing: Bool }
        _ = try? await client.rpc("set_dm_typing", params: P(conv_id: conversationID, typing: typing)).execute()
    }

    func markRead(conversationID: UUID) async {
        struct P: Encodable { let conv_id: UUID }
        _ = try? await client.rpc("mark_dm_read", params: P(conv_id: conversationID)).execute()
    }

    func editMessage(messageID: UUID, newText: String) async throws -> DMMessage {
        let res = try await client.rpc("edit_dm_message", params: EditParams(msg_id: messageID, new_body: newText)).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func deleteMessageForAll(messageID: UUID) async throws -> DMMessage {
        let res = try await client.rpc("delete_dm_message_for_all", params: DeleteAllParams(msg_id: messageID)).execute()
        return try decodeObject(res.data) as DMMessage
    }

    func hideMessageForMe(conversationID: UUID, messageID: UUID) async {
        _ = try? await client.rpc("hide_dm_message_for_me", params: HideParams(conv_id: conversationID, msg_id: messageID)).execute()
    }

    // MARK: - Mute / Unmute (con fallback local)
    /// Marca una conversación como silenciada o no. Si el RPC `set_dm_mute` no existe, guarda localmente.
    func setMuted(conversationID: UUID, mute: Bool) async {
        struct P: Encodable { let conv_id: UUID; let p_mute: Bool }
        if (try? await client.rpc("set_dm_mute", params: P(conv_id: conversationID, p_mute: mute)).execute()) != nil {
            LocalMuteStore.shared.set(conversationID: conversationID, muted: mute) // mantener cache
            return
        }
        // Fallback local (solo UX)
        LocalMuteStore.shared.set(conversationID: conversationID, muted: mute)
    }

    /// Devuelve si la conversación está silenciada. Intenta RPC `get_dm_mute`; si no existe, usa caché local.
    func isMuted(conversationID: UUID) async -> Bool {
        struct P: Encodable { let conv_id: UUID }
        if let res = try? await client.rpc("get_dm_mute", params: P(conv_id: conversationID)).execute(),
           let dict = try? JSONSerialization.jsonObject(with: res.data) as? [String: Any] {

            // Respuestas posibles: {"is_muted":true} o {"0":{"is_muted":true}}
            if let muted = dict["is_muted"] as? Bool {
                LocalMuteStore.shared.set(conversationID: conversationID, muted: muted)
                return muted
            }
            if let first = dict.values.first as? [String: Any],
               let muted = first["is_muted"] as? Bool {
                LocalMuteStore.shared.set(conversationID: conversationID, muted: muted)
                return muted
            }
        }
        // Fallback local
        return LocalMuteStore.shared.isMuted(conversationID: conversationID)
    }

    // MARK: - Eliminar conversación (para mí)
    /// Deja una conversación (la elimina para el usuario). Intenta RPC `leave_dm_conversation`; si falla, borra la membresía directa (RLS requerida).
    func deleteConversationForMe(conversationID: UUID) async throws {
        struct P: Encodable { let conv_id: UUID }
        if (try? await client.rpc("leave_dm_conversation", params: P(conv_id: conversationID)).execute()) != nil {
            return
        }
        // Fallback: intenta borrar tu fila en dm_members (si RLS lo permite)
        _ = try? await client
            .from("dm_members")
            .delete()
            .eq("conversation_id", value: conversationID)
            .execute()
    }

    // MARK: - Realtime (chat)
    struct RealtimeHandlers {
        var onInserted: ((DMMessage) -> Void)?
        var onUpdated:  ((DMMessage) -> Void)?
        var onDeletedGlobal: ((UUID) -> Void)?
        var onTypingChanged: ((UUID, Bool) -> Void)?
        var onMembersUpdated: (([DMMember]) -> Void)?
    }

    @discardableResult
    func subscribe(conversationID: UUID, handlers: RealtimeHandlers) async -> RealtimeChannelV2 {
        if subscribing.contains(conversationID), let ch = channels[conversationID] { return ch }
        subscribing.insert(conversationID); defer { subscribing.remove(conversationID) }
        await unsubscribe(conversationID: conversationID)

        let channel = client.realtimeV2.channel("dm:\(conversationID.uuidString)")
        channels[conversationID] = channel
        log("subscribing to dm:\(conversationID.uuidString)")

        let filter = "conversation_id=eq.\(conversationID.uuidString)"

        _ = channel.onPostgresChange(
            InsertAction.self, schema: "public", table: "dm_messages", filter: filter
        ) { [weak self] change in
            guard let self else { return }
            if let data = try? JSONEncoder().encode(change.record),
               let msg  = try? self.decoder.decode(DMMessage.self, from: data) { handlers.onInserted?(msg) }
        }

        _ = channel.onPostgresChange(
            UpdateAction.self, schema: "public", table: "dm_messages", filter: filter
        ) { [weak self] change in
            guard let self else { return }
            if let data = try? JSONEncoder().encode(change.record),
               let msg  = try? self.decoder.decode(DMMessage.self, from: data) {
                if msg.deleted_for_all_at != nil { handlers.onDeletedGlobal?(msg.id) }
                else { handlers.onUpdated?(msg) }
            }
        }

        _ = channel.onPostgresChange(
            UpdateAction.self, schema: "public", table: "dm_members", filter: filter
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                if let mems = try? await self.fetchMembers(conversationID: conversationID) {
                    handlers.onMembersUpdated?(mems)
                    if let typingUser = mems.first(where: { $0.is_typing == true })?.autor_id {
                        handlers.onTypingChanged?(typingUser, true)
                    } else if let any = mems.first?.autor_id {
                        handlers.onTypingChanged?(any, false)
                    }
                }
            }
        }

        await channel.subscribe()
        log("subscribed dm:\(conversationID.uuidString)")
        return channel
    }

    func unsubscribe(conversationID: UUID) async {
        if let ch = channels[conversationID] {
            await ch.unsubscribe()
            channels.removeValue(forKey: conversationID)
            log("unsubscribed", conversationID)
        }
    }

    // MARK: - Realtime Inbox (preview/orden)
    func subscribeInbox(
        conversationIDs: [UUID],
        onConversationBumped: @escaping (UUID) -> Void
    ) async {
        let wanted = Set(conversationIDs)
        for (id, ch) in inboxChannels where !wanted.contains(id) {
            await ch.unsubscribe()
            inboxChannels.removeValue(forKey: id)
            log("inbox unsubscribed", id)
        }
        for convID in wanted {
            if inboxChannels[convID] != nil { continue }
            let ch = client.realtimeV2.channel("inbox:\(convID.uuidString)")
            inboxChannels[convID] = ch
            let filter = "conversation_id=eq.\(convID.uuidString)"
            _ = ch.onPostgresChange(InsertAction.self, schema: "public", table: "dm_messages", filter: filter) { _ in onConversationBumped(convID) }
            _ = ch.onPostgresChange(UpdateAction.self, schema: "public", table: "dm_messages", filter: filter) { _ in onConversationBumped(convID) }
            _ = ch.onPostgresChange(DeleteAction.self, schema: "public", table: "dm_messages", filter: filter) { _ in onConversationBumped(convID) }
            _ = ch.onPostgresChange(UpdateAction.self, schema: "public", table: "dm_conversations", filter: "id=eq.\(convID.uuidString)") { _ in onConversationBumped(convID) }
            await ch.subscribe()
            log("inbox subscribed inbox:\(convID.uuidString)")
        }
    }
}

// MARK: - Almacén local (fallback) para Mute

final class LocalMuteStore {
    static let shared = LocalMuteStore()
    private let key = "dm.mute.store"
    private var setIDs: Set<String>

    private init() {
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            setIDs = Set(data)
        } else {
            setIDs = []
        }
    }

    func isMuted(conversationID: UUID) -> Bool {
        setIDs.contains(conversationID.uuidString)
    }

    func set(conversationID: UUID, muted: Bool) {
        if muted { setIDs.insert(conversationID.uuidString) }
        else { setIDs.remove(conversationID.uuidString) }
        UserDefaults.standard.set(Array(setIDs), forKey: key)
    }
}


extension DMMessagingService {
    /// Devuelve el conteo exacto de no leídos para una conversación usando el RPC `get_dm_unread_count`.
    /// Si el RPC no existe o falla, devuelve 0.
    func unreadCount(conversationID: UUID) async -> Int {
        struct P: Encodable { let conv_id: UUID }
        struct R: Decodable { let count: Int }
        do {
            let res = try await client
                .rpc("get_dm_unread_count", params: P(conv_id: conversationID))
                .execute()

            // Intenta decodificar { "count": <Int> } o lista con primero
            if let obj = try? JSONDecoder().decode(R.self, from: res.data) {
                return obj.count
            }
            if let arr = try? JSONDecoder().decode([R].self, from: res.data), let first = arr.first {
                return first.count
            }
            // fallback para respuestas tipo {"get_dm_unread_count": 3}
            if let dict = try? JSONSerialization.jsonObject(with: res.data) as? [String: Any],
               let c = (dict["get_dm_unread_count"] as? Int) ??
                       (dict["count"] as? Int) {
                return c
            }
        } catch {
            #if DEBUG
            print("[DM] unreadCount RPC error:", error.localizedDescription)
            #endif
        }
        return 0
    }
}
