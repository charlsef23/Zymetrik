import Foundation
import Supabase
import UIKit

struct FeedbackInsert: Codable {
    let autor_id: UUID
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
}

final class FeedbackService {
    static let shared = FeedbackService()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    /// Sube una imagen JPEG al bucket `feedback` y devuelve la ruta guardada.
    func subirCaptura(_ data: Data, userID: UUID) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let path = "\(userID.uuidString)/\(filename)"
        try await client.storage
            .from("feedback")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: false))
        return path
    }

    /// Inserta el registro en la tabla `feedback`.
    func enviarFeedback(_ payload: FeedbackInsert) async throws {
        _ = try await client
            .from("feedback")
            .insert(payload)
            .execute()
    }

    // Helpers
    func currentUserID() async throws -> UUID {
        let user = try await client.auth.session.user
        return user.id
    }

    static func appVersion() -> String? {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let v, let b { return "\(v) (\(b))" }
        return v ?? b
    }

    static func deviceModel() -> String {
        UIDevice.current.model
    }

    static func osVersion() -> String {
        "iOS " + UIDevice.current.systemVersion
    }
}
