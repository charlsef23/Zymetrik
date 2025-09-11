import Foundation
import Supabase

// MARK: - Cargar lista de logros con estado del usuario
extension SupabaseService {
    /// Devuelve todos los logros con su estado (desbloqueado/pendiente) para el usuario actual.
    func fetchLogrosCompletos() async throws -> [LogroConEstado] {
        let userID = try await client.auth.session.user.id.uuidString

        // 1) Logros definidos (incluye color si existe)
        let logrosResponse = try await client
            .from("logros")
            .select()
            .order("orden", ascending: true)
            .execute()

        let logros = try logrosResponse.decodedList(to: Logro.self)

        // 2) Logros del usuario actual
        let desbloqueadosResponse = try await client
            .from("logros_usuario")
            .select("logro_id, conseguido_en")
            .eq("autor_id", value: userID)
            .execute()

        let desbloqueados = try desbloqueadosResponse.decodedList(to: LogroUsuario.self)
        let mapaDesbloqueados = Dictionary(
            uniqueKeysWithValues: desbloqueados.map { ($0.logro_id, $0.conseguido_en) }
        )

        // 3) Combinar catálogo + estado del usuario
        return logros.map { logro in
            LogroConEstado(
                id: logro.id,
                titulo: logro.titulo,
                descripcion: logro.descripcion,
                icono_nombre: logro.icono_nombre,
                desbloqueado: mapaDesbloqueados[logro.id] != nil,
                fecha: mapaDesbloqueados[logro.id],
                color: logro.color
            )
        }
    }
}

// MARK: - Utilidad opcional: Insertar (si no existe) un logro para el usuario actual
extension SupabaseService {
    /// Inserta el logro en `logros_usuario` si no existía.
    /// - Returns: `true` si se insertó (nuevo); `false` si ya estaba desbloqueado.
    @discardableResult
    func desbloquearLogro(logroID: UUID) async throws -> Bool {
        let userID = try await client.auth.session.user.id
        let nuevo = NuevoLogroUsuario(logro_id: logroID, autor_id: userID)

        do {
            _ = try await client
                .from("logros_usuario")
                .insert([nuevo])
                .execute()
            print("✅ Logro \(logroID) desbloqueado (nuevo)")
            return true
        } catch {
            if let e = error as? PostgrestError {
                // Variantes típicas de unicidad/duplicado
                if e.message.localizedCaseInsensitiveContains("duplicate")
                    || e.message.localizedCaseInsensitiveContains("already exists")
                    || (e.hint?.localizedCaseInsensitiveContains("already exists") ?? false) {
                    print("ℹ️ Logro \(logroID) ya estaba desbloqueado")
                    return false
                }
            }
            throw error
        }
    }
}

// MARK: - Recomendado: sincronizar logros por usuario en servidor (RPC)
extension SupabaseService {
    /// Llama al RPC `award_achievements()` y devuelve los IDs de logros recién desbloqueados.
    func awardAchievementsRPC() async -> [UUID] {
        do {
            let response = try await client
                .rpc("award_achievements")
                .execute()

            let data = response.data // <- no opcional en tu SDK

            // Si el body viene vacío o "null", no hay nuevos logros
            if data.isEmpty {
                return []
            }
            if let s = String(data: data, encoding: .utf8),
               s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "null" {
                return []
            }

            // El RPC devuelve uuid[] -> JSON array puro
            let ids = try JSONDecoder().decode([UUID].self, from: data)
            return ids
        } catch {
            print("❌ RPC award_achievements falló:", error)
            return []
        }
    }
}
