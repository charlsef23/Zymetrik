import Foundation

public enum DeliveryState: String, Codable {
    case pending, sent, failed
}

public struct DMMessage: Codable, Identifiable, Hashable {
    public let id: UUID
    public let conversation_id: UUID
    public let autor_id: UUID
    public var content: String
    public let created_at: Date
    public let client_tag: String?
    public let edited_at: Date?
    public let deleted_for_all_at: Date?
    // Solo UI
    public var _delivery: DeliveryState? = nil

    enum CodingKeys: String, CodingKey {
        case id, conversation_id, autor_id, content,
             created_at, client_tag, edited_at, deleted_for_all_at
    }

    public static func == (lhs: DMMessage, rhs: DMMessage) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

public struct DMConversation: Codable, Identifiable, Hashable {
    public let id: UUID
    public let is_group: Bool
    public let created_at: Date?
    public let last_message_at: Date?
}

public struct DMMember: Codable, Identifiable, Hashable {
    public var id: String { "\(conversation_id.uuidString)-\(autor_id.uuidString)" }
    public let conversation_id: UUID
    public let autor_id: UUID
    public let joined_at: Date?
    public let last_read_at: Date?
    public let is_typing: Bool?
    public let typing_updated_at: Date?
}

public struct PerfilLite: Codable, Identifiable, Hashable {
    public let id: UUID
    public let username: String
    public let avatar_url: String?
}

// Item para el inbox
public struct DMInboxItem: Identifiable, Hashable {
    public let id: UUID
    public let conversation: DMConversation
    public let otherPerfil: PerfilLite?
    public var lastMessagePreview: String?
    public var lastAt: Date?
    public var unreadCount: Int = 0
    public var isOnline: Bool = false
    var isMuted: Bool = false
}
