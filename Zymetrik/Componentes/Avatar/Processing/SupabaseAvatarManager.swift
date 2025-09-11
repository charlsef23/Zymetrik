import Supabase
import UIKit
import Foundation

class SupabaseAvatarManager {
    static let shared = SupabaseAvatarManager()
    private init() {}
    
    private let imageProcessor = ImageProcessor()
    
    // MARK: - Upload Avatar Completo
    
    func uploadAvatarComplete(_ image: UIImage, userID: String) async throws -> String {
        // Eliminar avatar anterior primero
        try await deleteOldAvatarForUser(userID: userID)
        
        // Procesar imagen
        let processedImage = ImageCropper.cropToSquare(image, size: 400)
        
        guard let imageData = imageProcessor.compressImage(processedImage, quality: 0.8) else {
            throw AvatarError.compressionFailed
        }
        
        // Generar nombre único
        let timestamp = Date().timeIntervalSince1970
        let fileName = "avatar_\(userID)_\(timestamp).jpg"
        let storagePath = "usuarios/\(fileName)"
        
        // Subir a Supabase Storage
        _ = try await SupabaseManager.shared.client.storage
            .from("avatars")
            .upload(
                storagePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
        
        // Obtener URL pública
        let publicURL = try SupabaseManager.shared.client.storage
            .from("avatars")
            .getPublicURL(path: storagePath)
        
        let avatarURL = publicURL.absoluteString
        
        // Actualizar perfil en base de datos
        try await updateProfileAvatar(userID: userID, avatarURL: avatarURL)
        
        // Guardar en cache
        AvatarCache.shared.setImage(processedImage, forKey: avatarURL)
        
        return avatarURL
    }
    
    // MARK: - Update Profile Avatar

    private func updateProfileAvatar(userID: String, avatarURL: String) async throws {
        struct Payload: Encodable {
            let avatar_url: String?
        }
        let payload = Payload(avatar_url: avatarURL)

        try await SupabaseManager.shared.client
            .from("perfil")
            .update(payload)                 // <-- ya no enviamos updated_at
            .eq("id", value: userID)
            .execute()
    }
    
    // MARK: - Delete Old Avatar for User
    
    private func deleteOldAvatarForUser(userID: String) async throws {
        // Obtener URL actual del avatar
        let response = try await SupabaseManager.shared.client
            .from("perfil")
            .select("avatar_url")
            .eq("id", value: userID)
            .single()
            .execute()
        
        if let data = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
           let oldAvatarURL = data["avatar_url"] as? String,
           !oldAvatarURL.isEmpty {
            await deleteOldAvatar(url: oldAvatarURL)
        }
    }
    
    // MARK: - Delete Old Avatar
    
    func deleteOldAvatar(url: String) async {
        guard let path = extractStoragePath(from: url) else { return }
        
        do {
            try await SupabaseManager.shared.client.storage
                .from("avatars")
                .remove(paths: [path])
            
            // Remover del cache
            AvatarCache.shared.removeImage(forKey: url)
        } catch {
            print("⚠️ Error eliminando avatar anterior: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractStoragePath(from url: String) -> String? {
        let components = url.components(separatedBy: "/avatars/")
        return components.count > 1 ? components[1] : nil
    }
}

// MARK: - Avatar Errors (que faltaba)
enum AvatarError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case invalidImage
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Error al comprimir la imagen"
        case .uploadFailed:
            return "Error al subir la imagen"
        case .invalidImage:
            return "Imagen no válida"
        case .networkError:
            return "Error de conexión"
        }
    }
}

// MARK: - Date Extension (que faltaba)
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - Estructura para actualización de perfil
private struct ProfileAvatarUpdate: Codable {
    let avatar_url: String
    let updated_at: String
}

// MARK: - Extensión con notificaciones
extension SupabaseAvatarManager {
    func uploadAvatarAndNotify(_ image: UIImage, userID: String) async throws -> String {
        let avatarURL = try await uploadAvatarComplete(image, userID: userID)
        
        // Notificar a toda la app que el avatar cambió
        await MainActor.run {
            NotificationCenter.default.post(
                name: .avatarDidUpdate,
                object: nil,
                userInfo: [
                    "userID": userID,
                    "avatarURL": avatarURL
                ]
            )
        }
        
        return avatarURL
    }
}
