import Supabase
import UIKit
import Foundation

class SupabaseAvatarManager {
    static let shared = SupabaseAvatarManager()
    private init() {}

    private let imageProcessor = ImageProcessor()

    // MARK: - Upload Avatar Completo
    func uploadAvatarComplete(_ image: UIImage, userID: String) async throws -> String {
        // 1) Eliminar avatar anterior
        try await deleteOldAvatarForUser(userID: userID)

        // 2) Normaliza orientación y recorta a 1:1 (400x400).
        //    Si prefieres auto-centrado por rostro, usa ImageCropper.smartCrop(_:to:)
        let normalized = image.normalizedUp()
        let processedImage = ImageCropper.centerSquare(normalized, size: 400)

        // 3) Comprimir
        guard let imageData = imageProcessor.compressImage(processedImage, quality: 0.8) else {
            throw AvatarError.compressionFailed
        }

        // 4) Subir a Storage
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "avatar_\(userID)_\(timestamp).jpg"
        let storagePath = "usuarios/\(fileName)"

        _ = try await SupabaseManager.shared.client.storage
            .from("avatars")
            .upload(
                storagePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        // 5) URL pública
        let publicURL = try SupabaseManager.shared.client.storage
            .from("avatars")
            .getPublicURL(path: storagePath)
        let avatarURL = publicURL.absoluteString

        // 6) Actualizar perfil
        try await updateProfileAvatar(userID: userID, avatarURL: avatarURL)

        // 7) Cache local
        AvatarCache.shared.setImage(processedImage, forKey: avatarURL)

        return avatarURL
    }

    // MARK: - Update Profile Avatar
    private func updateProfileAvatar(userID: String, avatarURL: String) async throws {
        struct Payload: Encodable { let avatar_url: String? }
        let payload = Payload(avatar_url: avatarURL)

        try await SupabaseManager.shared.client
            .from("perfil")
            .update(payload)
            .eq("id", value: userID)
            .execute()
    }

    // MARK: - Delete Old Avatar for User
    private func deleteOldAvatarForUser(userID: String) async throws {
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
            AvatarCache.shared.removeImage(forKey: url)
        } catch {
            print("⚠️ Error eliminando avatar anterior: \(error)")
        }
    }

    // MARK: - Helpers
    private func extractStoragePath(from url: String) -> String? {
        let components = url.components(separatedBy: "/avatars/")
        return components.count > 1 ? components[1] : nil
    }
}

// MARK: - Avatar Errors
enum AvatarError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case invalidImage
    case networkError

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Error al comprimir la imagen"
        case .uploadFailed:      return "Error al subir la imagen"
        case .invalidImage:      return "Imagen no válida"
        case .networkError:      return "Error de conexión"
        }
    }
}

// MARK: - Notificación
extension SupabaseAvatarManager {
    func uploadAvatarAndNotify(_ image: UIImage, userID: String) async throws -> String {
        let avatarURL = try await uploadAvatarComplete(image, userID: userID)
        await MainActor.run {
            NotificationCenter.default.post(
                name: .avatarDidUpdate,
                object: nil,
                userInfo: ["userID": userID, "avatarURL": avatarURL]
            )
        }
        return avatarURL
    }
}
