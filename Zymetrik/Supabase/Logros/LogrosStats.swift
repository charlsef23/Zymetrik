import Foundation
import Supabase

// MARK: - Estadísticas de logros (única definición aquí)
extension SupabaseService {

    struct LogrosStats {
        let totalLogros: Int
        let logrosDesbloqueados: Int
        let porcentajeCompletado: Double
        let ultimoLogro: String?
        let ultimaFecha: Date?
    }

    func fetchLogrosStats() async throws -> LogrosStats {
        let userID = try await client.auth.session.user.id.uuidString
        guard let uuid = UUID(uuidString: userID) else {
            throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID de usuario inválido"])
        }
        return try await fetchLogrosStats(autorId: uuid)
    }

    func fetchLogrosStats(autorId: UUID) async throws -> LogrosStats {
        // Total de logros disponibles
        let totalLogros: Int = try await client
            .from("logros")
            .select("id", count: .exact)
            .execute()
            .count ?? 0

        // Logros desbloqueados por el usuario
        let logrosDesbloqueados: Int = try await client
            .from("logros_usuario")
            .select("id", count: .exact)
            .eq("autor_id", value: autorId.uuidString)
            .execute()
            .count ?? 0

        // Último logro desbloqueado con join a título y color
        struct UltimoLogro: Decodable {
            let logro_id: UUID
            let conseguido_en: String?
            let titulo: String
            let color: String?
        }

        let ultimoLogroResponse: [UltimoLogro]? = try? await client
            .from("logros_usuario")
            .select("logro_id,conseguido_en,logros!inner(titulo,color)")
            .eq("autor_id", value: autorId.uuidString)
            .order("conseguido_en", ascending: false)
            .limit(1)
            .execute()
            .decodedList(to: UltimoLogro.self)

        let ultimoLogro = ultimoLogroResponse?.first

        // Parseo robusto de fechas ISO8601 con/ sin fracciones
        let f1 = ISO8601DateFormatter(); f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter(); f2.formatOptions = [.withInternetDateTime]

        let fechaParseada: Date? = ultimoLogro?.conseguido_en.flatMap { f1.date(from: $0) ?? f2.date(from: $0) }

        return LogrosStats(
            totalLogros: totalLogros,
            logrosDesbloqueados: logrosDesbloqueados,
            porcentajeCompletado: totalLogros > 0 ? Double(logrosDesbloqueados) / Double(totalLogros) : 0.0,
            ultimoLogro: ultimoLogro?.titulo,
            ultimaFecha: fechaParseada
        )
    }
}
