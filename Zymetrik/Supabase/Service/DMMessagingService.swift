import Foundation
import Supabase

/// Servicio de mensajería DM para Supabase (RPC-based)
final class DMMessagingService {
    static let shared = DMMessagingService()
    private init() {}

    // Ajusta si tu manager es distinto
    private let client = SupabaseManager.shared.client

    // Pollers por conversación
    private var pollers: [UUID: Task<Void, Never>] = [:]
    public var pollingInterval: TimeInterval = 3

    // MARK: - Decoders robustos (fechas variables)
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

    private func decodeList<T: Decodable>(_ data: Data) throws -> [T] {
        do { return try decoder.decode([T].self, from: data) }
        catch {
            print("❌ decodeList error:", error, String(data: data, encoding: .utf8) ?? "")
            throw error
        }
    }

    private func decodeObject<T: Decodable>(_ data: Data) throws -> T {
        do { return try decoder.decode(T.self, from: data) }
        catch {
            print("❌ decodeObject error:", error, String(data: data, encoding: .utf8) ?? "")
            throw error
        }
    }

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

    // MARK: - RPCs
    func getOrCreateDM(with otherUserID: UUID) async throws -> UUID {
        let myID = try await currentUserID()
        let params = GetOrCreateDMParams(a: myID.uuidString, b: otherUserID.uuidString)
        let res = try await client.rpc("get_or_create_dm", params: params).execute()
        let data = res.data

        // soporta: objeto {id:"..."}, {"get_or_create_dm":"..."}, string "uuid", ["uuid"], o texto plano
        if let any = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] {
            if let v = any["get_or_create_dm"] as? String, let id = UUID(uuidString: v) { return id }
            if let v = any["id"] as? String, let id = UUID(uuidString: v) { return id }
            if let zero = any["0"] as? [String: Any], let v = zero["id"] as? String, let id = UUID(uuidString: v) { return id }
        }
        if let s = try? JSONDecoder().decode(String.self, from: data), let id = UUID(uuidString: s) { return id }
        if let arr = try? JSONDecoder().decode([String].self, from: data), let first = arr.first, let id = UUID(uuidString: first) { return id }
        if let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"")), let id = UUID(uuidString: raw) { return id }

        print("RPC get_or_create_dm payload:", String(data: data, encoding: .utf8) ?? "<binario>")
        throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Respuesta RPC inválida al crear/obtener DM"])
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
        if let one: PerfilLite = try? decodeObject(res.data) { return one }
        let list: [PerfilLite] = try decodeList(res.data)
        guard let first = list.first else {
            throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])
        }
        return first
    }

    /// Trae mensajes ordenados asc (viejo→nuevo).
    func fetchMessages(conversationID: UUID, before: Date? = nil, after: Date? = nil, pageSize: Int = 30) async throws -> [DMMessage] {
        let iso = ISO8601DateFormatter()
        let params = GetDMMessagesParams(
            conv_id: conversationID.uuidString,
            before_ts: before.map { iso.string(from: $0) },
            after_ts:  after.map { iso.string(from: $0) },
            page_size: pageSize
        )
        let res = try await client.rpc("get_dm_messages", params: params).execute()
        return try decodeList(res.data) // RPC ya ordena asc
    }

    /// Envío con reconciliación: el backend devuelve la fila insertada.
    func sendMessage(conversationID: UUID, text: String, clientTag: String) async throws -> DMMessage {
        let payload = SendDMParams(conv_id: conversationID.uuidString, body: text, client_tag: clientTag)
        let res = try await client.rpc("send_dm_message", params: payload).execute()
        return try decodeObject(res.data) as DMMessage
    }

    // MARK: - Polling incremental
    func startPolling(conversationID: UUID,
                      since initialDate: Date?,
                      onInsert: @escaping (DMMessage) -> Void) {
        stopPolling(conversationID: conversationID)
        let lastRef = Locked<Date?>(initialDate)

        pollers[conversationID] = Task.detached { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let after = lastRef.value
                    let news = try await self.fetchMessages(conversationID: conversationID, after: after, pageSize: 50)
                    if !news.isEmpty {
                        for m in news { onInsert(m) }
                        lastRef.value = news.map(\.created_at).max() ?? after
                    }
                } catch {
                    // Ignora errores transitorios
                }
                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
            }
        }
    }

    func stopPolling(conversationID: UUID) {
        pollers[conversationID]?.cancel()
        pollers.removeValue(forKey: conversationID)
    }
}

// Pequeño contenedor thread-safe
final class Locked<T> {
    private let q = DispatchQueue(label: "lock.\(UUID().uuidString)")
    private var _v: T
    init(_ v: T) { _v = v }
    var value: T {
        get { q.sync { _v } }
        set { q.sync { _v = newValue } }
    }
}
