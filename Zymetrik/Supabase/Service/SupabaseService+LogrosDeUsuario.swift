import Foundation
import Supabase

extension SupabaseService {
    /// Devuelve todos los logros con su estado (desbloqueado o no) para el `autorId` indicado.
    /// No ejecuta ningún award, solo lectura.
    func fetchLogrosCompletos(autorId: UUID) async throws -> [LogroConEstado] {
        // 1) Catálogo de logros
        struct LogroRow: Decodable {
            let id: UUID
            let titulo: String
            let descripcion: String?
            let icono_nombre: String?
            let color: String?
            let orden: Int?
        }

        let logrosReq: [LogroRow] = try await client
            .from("logros")
            .select("id,titulo,descripcion,icono_nombre,color,orden")
            .order("orden", ascending: true)
            .execute()
            .decodedList(to: LogroRow.self)

        // 2) Logros desbloqueados por el usuario (+ fecha)
        struct LogroUsuarioRow: Decodable {
            let logro_id: UUID
            let conseguido_en: String? // ISO8601
        }

        let desbloqReq: [LogroUsuarioRow] = try await client
            .from("logros_usuario")
            .select("logro_id,conseguido_en")
            .eq("autor_id", value: autorId.uuidString)
            .execute()
            .decodedList(to: LogroUsuarioRow.self)

        var unlocked: [UUID: Date?] = [:]
        // Intenta con fracciones y sin fracciones
        let df1 = ISO8601DateFormatter()
        df1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let df2 = ISO8601DateFormatter()

        for row in desbloqReq {
            let date: Date?
            if let s = row.conseguido_en {
                date = df1.date(from: s) ?? df2.date(from: s)
            } else {
                date = nil
            }
            unlocked[row.logro_id] = date
        }

        // 3) Mapear al modelo de UI
        // Según tu error anterior, el init de LogroConEstado es:
        // init(id:titulo:descripcion:icono_nombre:desbloqueado:fecha:color:)
        let result: [LogroConEstado] = logrosReq.map { base in
            let isUnlocked = unlocked[base.id] != nil
            let fecha = unlocked[base.id] ?? nil

            // Defaults seguros para opcionales
            let desc  = base.descripcion  ?? ""
            let icon  = base.icono_nombre ?? "rosette"
            let color = base.color        ?? "#888888"

            return LogroConEstado(
                id: base.id,
                titulo: base.titulo,
                descripcion: desc,
                icono_nombre: icon,
                desbloqueado: isUnlocked,
                fecha: fecha,
                color: color
            )
        }

        return result
    }
}
