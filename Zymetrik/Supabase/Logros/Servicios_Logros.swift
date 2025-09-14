import Foundation
import Supabase

// MARK: - Extensión de SupabaseService para Logros (RPC + catálogo)
extension SupabaseService {

    /// Devuelve los IDs de logros recién otorgados por el backend (puede ser vacío).
    func awardAchievementsRPC() async -> [UUID] {
        do {
            let res = try await client
                .rpc("award_achievements")
                .execute()

            // Si el RPC devuelve `null` o vacío, no hay logros
            if res.data.isEmpty { return [] }
            if let s = String(data: res.data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               s == "null" || s == "[]" {
                return []
            }

            guard let uuids = try? JSONDecoder().decode([UUID].self, from: res.data) else {
                return []
            }
            return uuids
        } catch {
            print("❌ awardAchievementsRPC error:", error)
            return []
        }
    }

    /// Obtiene el catálogo de logros y los marca con el estado del usuario actual.
    func fetchLogrosCompletos() async throws -> [LogroConEstado] {
        let userID = try await client.auth.session.user.id.uuidString
        guard let uuid = UUID(uuidString: userID) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        return try await fetchLogrosCompletos(autorId: uuid)
    }

    /// Variante por autorId concreto.
    func fetchLogrosCompletos(autorId: UUID) async throws -> [LogroConEstado] {
        struct LogroRow: Decodable {
            let id: UUID
            let titulo: String
            let descripcion: String?
            let icono_nombre: String?
            let color: String?
            let orden: Int?
        }
        struct LogroUsuarioRow: Decodable {
            let logro_id: UUID
            let conseguido_en: String?
        }

        // 1) Catálogo
        let logros: [LogroRow] = try await client
            .from("logros")
            .select("id,titulo,descripcion,icono_nombre,color,orden")
            .order("orden", ascending: true)
            .execute()
            .decodedList(to: LogroRow.self)

        // 2) Desbloqueados del usuario
        let desbloqueados: [LogroUsuarioRow] = try await client
            .from("logros_usuario")
            .select("logro_id,conseguido_en")
            .eq("autor_id", value: autorId.uuidString)
            .execute()
            .decodedList(to: LogroUsuarioRow.self)

        // 3) Mapear fechas (ISO8601)
        let f1 = ISO8601DateFormatter(); f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter(); f2.formatOptions = [.withInternetDateTime]

        var unlocked: [UUID: Date?] = [:]
        for row in desbloqueados {
            let date = row.conseguido_en.flatMap { f1.date(from: $0) ?? f2.date(from: $0) }
            unlocked[row.logro_id] = date
        }

        // 4) Combinar catálogo + estado
        return logros.map { l in
            let isUnlocked = unlocked[l.id] != nil
            let fecha = unlocked[l.id] ?? nil
            return LogroConEstado(
                id: l.id,
                titulo: l.titulo,
                descripcion: l.descripcion ?? "",
                icono_nombre: l.icono_nombre ?? "rosette",
                desbloqueado: isUnlocked,
                fecha: fecha,
                color: l.color ?? "#888888"
            )
        }
    }
}
