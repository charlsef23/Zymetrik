import Foundation
import Supabase

struct SupabaseService {
    static let shared = SupabaseService()
    let client = SupabaseManager.shared.client
    
    func guardarEntrenamiento(fecha: Date, ejercicios: [Ejercicio]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        
        let fechaISO = fecha.formatted(.iso8601)
        let entrenamientoId = UUID()
        
        let entrenamiento = NuevoEntrenamiento(
            id: entrenamientoId,
            user_id: userId,
            fecha: fechaISO
        )
        
        try await client
            .from("entrenamientos")
            .insert(entrenamiento)
            .execute()
        
        let ejerciciosInsertables = ejercicios.map { ejercicio in
            EjercicioEnEntrenamiento(
                id: UUID(),
                entrenamiento_id: entrenamientoId,
                ejercicio_id: ejercicio.id
            )
        }
        
        try await client
            .from("ejercicios_en_entrenamiento")
            .insert(ejerciciosInsertables)
            .execute()
    }
    
}
