import Foundation

/// Proyección local del estado de suscripción
struct SubscriptionSnapshot: Codable {
    var isPro: Bool
    var productId: String?
    var environment: String?           // "Sandbox"/"Production"
    var status: String?                // "active"/"expired"…
    var willRenew: Bool?
    var originalTransactionId: String?
    var expiresAt: Date?
    var lastEvent: String?             // "SUBSCRIBED"/"RESTORE"/"REFRESH"…
}

/// Payload para RPC api_assn_upsert(p jsonb)
struct ASSNUpsertPayload: Encodable {
    let autor_id: UUID
    let is_pro: Bool?
    let product_id: String?
    let expires_at: String?
    let environment: String?
    let status: String?
    let will_renew: Bool?
    let original_transaction_id: String?
    let last_event: String?
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
