import Foundation
import Supabase

extension SupabaseService {
    /// Cancela la rutina activa del usuario y borra días futuros (RPC: api_cancel_active_routine)
    func cancelActiveRoutine() async throws {
        _ = try await SupabaseManager.shared.client
            .rpc("api_cancel_active_routine")
            .execute()
    }
}
