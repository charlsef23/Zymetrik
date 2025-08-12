import Foundation

// MARK: - Conversación
public struct DMConversation: Codable, Identifiable, Hashable {
    public let id: UUID
    public let is_group: Bool
    public let created_at: Date?        // puede venir null
    public let last_message_at: Date?   // puede venir null (si no hay mensajes)

    public init(id: UUID, is_group: Bool, created_at: Date?, last_message_at: Date?) {
        self.id = id
        self.is_group = is_group
        self.created_at = created_at
        self.last_message_at = last_message_at
    }

    enum CodingKeys: String, CodingKey {
        case id
        case is_group
        case created_at
        case last_message_at
    }
}

// MARK: - Miembro
public struct DMMember: Codable, Identifiable, Hashable {
    public var id: String { "\(conversation_id.uuidString)-\(autor_id.uuidString)" }
    public let conversation_id: UUID
    public let autor_id: UUID
    public let joined_at: Date?

    public init(conversation_id: UUID, autor_id: UUID, joined_at: Date?) {
        self.conversation_id = conversation_id
        self.autor_id = autor_id
        self.joined_at = joined_at
    }

    enum CodingKeys: String, CodingKey {
        case conversation_id
        case autor_id
        case joined_at
    }
}

// MARK: - Mensaje
public struct DMMessage: Codable, Identifiable, Hashable {
    public let id: UUID
    public let conversation_id: UUID
    public let autor_id: UUID
    public let content: String
    public let created_at: Date   // NOT NULL en DB

    public init(id: UUID, conversation_id: UUID, autor_id: UUID, content: String, created_at: Date) {
        self.id = id
        self.conversation_id = conversation_id
        self.autor_id = autor_id
        self.content = content
        self.created_at = created_at
    }

    enum CodingKeys: String, CodingKey {
        case id
        case conversation_id
        case autor_id
        case content
        case created_at
    }

    // Importante: dedupe por id
    public static func == (lhs: DMMessage, rhs: DMMessage) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Perfil mínimo
public struct PerfilLite: Codable, Identifiable, Hashable {
    public let id: UUID
    public let username: String
    public let avatar_url: String?

    public init(id: UUID, username: String, avatar_url: String?) {
        self.id = id
        self.username = username
        self.avatar_url = avatar_url
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatar_url
    }
}
