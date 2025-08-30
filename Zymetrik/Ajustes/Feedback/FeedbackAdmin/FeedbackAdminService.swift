import Foundation
import Supabase

struct FeedbackRecord: Codable, Identifiable {
    let id: UUID
    let autor_id: UUID
    let creado_en: Date
    let tipo: String
    let titulo: String
    let mensaje: String
    let categoria: String?
    let severidad: String?
    let calificacion: Int?
    let email_contacto: String?
    let app_version: String?
    let os_version: String?
    let device_model: String?
    let screenshot_path: String?
    let estado: String
}

final class FeedbackAdminService {
    static let shared = FeedbackAdminService()
    private init() {}
    private var client: SupabaseClient { SupabaseManager.shared.client }

    /// Lista feedbacks. Los filtros se aplican en cliente para evitar incompatibilidades de builder.
    func fetchFeedbacks(
        tipo: String? = nil,
        estado: String? = nil,
        severidad: String? = nil,
        search: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [FeedbackRecord] {
        // Base query: orden y paginación en el servidor
        let q = client
            .from("feedback")
            .select("""
              id, autor_id, creado_en, tipo, titulo, mensaje, categoria,
              severidad, calificacion, email_contacto, app_version,
              os_version, device_model, screenshot_path, estado
            """, head: false)
            .order("creado_en", ascending: false)
            .range(from: offset, to: offset + limit - 1)

        let resp = try await q.execute()

        // Si tienes tu helper:
        // let list = try resp.decodedList(to: FeedbackRecord.self)
        // Fallback genérico:
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var list = try decoder.decode([FeedbackRecord].self, from: resp.data)

        // Filtros en cliente
        if let tipo, !tipo.isEmpty {
            list = list.filter { $0.tipo == tipo }
        }
        if let estado, !estado.isEmpty {
            list = list.filter { $0.estado == estado }
        }
        if let severidad, !severidad.isEmpty {
            list = list.filter { $0.severidad == severidad }
        }
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let s = search.lowercased()
            list = list.filter { rec in
                rec.titulo.lowercased().contains(s) || rec.mensaje.lowercased().contains(s)
            }
        }

        return list
    }

    /// Cambia el estado (requiere policy de update para admins).
    func actualizarEstado(id: UUID, nuevoEstado: String) async throws {
        _ = try await client
            .from("feedback")
            .update(["estado": nuevoEstado])
            .eq("id", value: id.uuidString) // <- esta eq suele existir sobre update; si no, usa filtro en cliente con RPC
            .execute()
    }

    /// URL firmada de la captura (el SDK devuelve URL directamente).
    func signedScreenshotURL(path: String, expiresInSeconds: Int = 3600) async throws -> URL {
        try await client.storage
            .from("feedback")
            .createSignedURL(path: path, expiresIn: expiresInSeconds)
    }
}
