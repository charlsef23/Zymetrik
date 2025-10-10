import Foundation
import Supabase

// MARK: - Tipos de notificación

public enum NotificationType: String, Codable, CaseIterable {
    case follow        // Te ha seguido
    case like_post     // Me gusta a post
    case like_comment  // Me gusta a comentario
    case comment       // Comentario en tu post
    case dm            // Mensaje directo
    case reminder      // Recordatorio
    
    public var tituloSeccion: String {
        switch self {
        case .follow:       return "Nuevos seguidores"
        case .like_post:    return "Me gustas"
        case .like_comment: return "Me gusta a comentario"
        case .comment:      return "Comentarios"
        case .dm:           return "Mensajes directos"
        case .reminder:     return "Recordatorios"
        }
    }
    
    public var sfSymbol: String {
        switch self {
        case .follow:       return "person.crop.circle.badge.plus"
        case .like_post:    return "heart.fill"
        case .like_comment: return "heart.text.square.fill"
        case .comment:      return "text.bubble.fill"
        case .dm:           return "paperplane.fill"
        case .reminder:     return "bell.fill"
        }
    }
}

// MARK: - Modelos

public struct NotificationActor: Codable, Equatable {
    public let id: UUID
    public let username: String
    public let nombre: String?
    public let avatar_url: String?
}

public struct AppNotification: Identifiable, Codable, Equatable {
    public let id: UUID
    public let type: NotificationType
    public let actor: NotificationActor
    public let message: String
    public let created_at: Date
    public let read_at: Date?
    
    public let post_id: UUID?
    public let comment_id: UUID?
    public let chat_id: UUID?
    
    public var isRead: Bool { read_at != nil }
}

// MARK: - Servicio

public struct NotificacionesService {
    public static let shared = NotificacionesService()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    /// Carga notificaciones desde la vista `notifications_enriched`.
    /// Si `onlyUnread = true` filtramos en memoria para evitar dependencias de operadores no disponibles en algunas versiones del builder.
    public func fetchNotifications(limit: Int = 100, onlyUnread: Bool = false) async throws -> [AppNotification] {
        let res = try await client
            .from("notifications_enriched")
            .select("""
                id,
                type,
                message,
                created_at,
                read_at,
                post_id,
                comment_id,
                chat_id,
                id_actor,
                username,
                nombre,
                avatar_url
            """)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        struct Row: Decodable {
            let id: UUID
            let type: NotificationType
            let message: String
            let created_at: Date
            let read_at: Date?
            let post_id: UUID?
            let comment_id: UUID?
            let chat_id: UUID?
            let id_actor: UUID
            let username: String
            let nombre: String?
            let avatar_url: String?
        }
        
        let rows = try res.decodedList(to: Row.self)
        var items = rows.map { r in
            AppNotification(
                id: r.id,
                type: r.type,
                actor: .init(id: r.id_actor, username: r.username, nombre: r.nombre, avatar_url: r.avatar_url),
                message: r.message,
                created_at: r.created_at,
                read_at: r.read_at,
                post_id: r.post_id,
                comment_id: r.comment_id,
                chat_id: r.chat_id
            )
        }
        if onlyUnread {
            items = items.filter { $0.read_at == nil }
        }
        return items
    }
    
    /// Marca una notificación como leída.
    public func markNotificationRead(_ id: UUID) async throws {
        _ = try await client
            .from("notifications")
            .update(["read_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Marca todas como leídas (RPC sin parámetros).
    public func markAllNotificationsRead() async throws {
        _ = try await client
            .rpc("api_notifications_mark_all_read")
            .execute()
    }
}
