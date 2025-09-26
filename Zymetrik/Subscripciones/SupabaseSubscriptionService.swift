import Foundation
import Supabase

enum SubscriptionSyncError: Error { case noUser }

final class SupabaseSubscriptionService {
    static let shared = SupabaseSubscriptionService()
    private init() {}

    /// Llama tu RPC api_assn_upsert(p jsonb)
    func upsert(snapshot: SubscriptionSnapshot) async throws {
        guard let uid = await SupabaseManager.shared.currentUserUUID() else {
            throw SubscriptionSyncError.noUser
        }

        let payload = ASSNUpsertPayload(
            autor_id: uid,
            is_pro: snapshot.isPro,
            product_id: snapshot.productId,
            expires_at: snapshot.expiresAt?.iso8601String,
            environment: snapshot.environment,
            status: snapshot.status,
            will_renew: snapshot.willRenew,
            original_transaction_id: snapshot.originalTransactionId,
            last_event: snapshot.lastEvent
        )

        // ✅ En el SDK de Swift se llama directamente a client.rpc
        _ = try await SupabaseManager.shared.client
            .rpc("api_assn_upsert", params: ["p": payload])
            .execute()
    }
}
