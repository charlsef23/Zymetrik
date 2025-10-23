import Supabase
import UIKit
import Foundation

class SupabaseAvatarManager {
    static let shared = SupabaseAvatarManager()
    private init() {}
    private let imageProcessor = ImageProcessor()

    func uploadAvatarComplete(_ image: UIImage, userID: String) async throws -> String {
        try await deleteOldAvatarForUser(userID: userID)

        // Normaliza + recorta 1:1 (400x400). Puedes usar smartCrop si prefieres rostro.
        let normalized = image.normalizedUp()
        let processedImage = ImageCropper.centerSquare(normalized, size: 400)

        guard let imageData = imageProcessor.compressImage(processedImage, quality: 0.8) else {
            throw AvatarError.compressionFailed
        }

        let ts = Int(Date().timeIntervalSince1970)
        let fileName = "avatar_\(userID)_\(ts).jpg"
        let storagePath = "usuarios/\(fileName)"

        _ = try await SupabaseManager.shared.client.storage
            .from("avatars")
            .upload(storagePath, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        let publicURL = try SupabaseManager.shared.client.storage
            .from("avatars")
            .getPublicURL(path: storagePath)
        let avatarURL = publicURL.absoluteString

        try await updateProfileAvatar(userID: userID, avatarURL: avatarURL)

        // Guarda en caché local (memoria+disco)
        AvatarCache.shared.setImage(processedImage, forKey: avatarURL)

        return avatarURL
    }

    private func updateProfileAvatar(userID: String, avatarURL: String) async throws {
        struct Payload: Encodable { let avatar_url: String? }
        try await SupabaseManager.shared.client
            .from("perfil")
            .update(Payload(avatar_url: avatarURL))
            .eq("id", value: userID)
            .execute()
    }

    private func deleteOldAvatarForUser(userID: String) async throws {
        let response = try await SupabaseManager.shared.client
            .from("perfil")
            .select("avatar_url")
            .eq("id", value: userID)
            .single()
            .execute()

        if let data = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
           let oldURL = data["avatar_url"] as? String, !oldURL.isEmpty {
            await deleteOldAvatar(url: oldURL)
        }
    }

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

    private func extractStoragePath(from url: String) -> String? {
        let comps = url.components(separatedBy: "/avatars/")
        return comps.count > 1 ? comps[1] : nil
    }
}

enum AvatarError: LocalizedError {
    case compressionFailed, uploadFailed, invalidImage, networkError
    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Error al comprimir la imagen"
        case .uploadFailed:      return "Error al subir la imagen"
        case .invalidImage:      return "Imagen no válida"
        case .networkError:      return "Error de conexión"
        }
    }
}

extension SupabaseAvatarManager {
    func uploadAvatarAndNotify(_ image: UIImage, userID: String) async throws -> String {
        let url = try await uploadAvatarComplete(image, userID: userID)
        await MainActor.run {
            NotificationCenter.default.post(name: .avatarDidUpdate, object: nil, userInfo: ["userID": userID, "avatarURL": url])
        }
        return url
    }
}
