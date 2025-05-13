import Foundation
import Supabase
import UIKit

class SupabaseImageUploader {
    static func uploadImage(_ image: UIImage, fileName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: -1)
        }

        let path = "\(fileName).jpg"

        // Subir imagen al bucket
        _ = try await SupabaseManager.shared.client
            .storage
            .from("post-images")
            .upload(path, data: imageData)

        // Construir URL pública (reemplaza con tu URL de Supabase)
        let baseURL = "https://eolcdkdqsoxkiaxmdgrv.supabase.co"
        let publicURL = "\(baseURL)/storage/v1/object/public/post-images/\(path)"

        return publicURL
    }
}
