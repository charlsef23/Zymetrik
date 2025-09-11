import UIKit
import ImageIO
import UniformTypeIdentifiers

enum FastImageLoader {
    static func downsampledImage(from url: URL, targetSize: CGSize) async -> UIImage? {
        // Esquemas permitidos
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return await downsampledImage(data: data, targetSize: targetSize)
        } catch {
            return nil
        }
    }

    static func downsampledImage(data: Data, targetSize: CGSize) async -> UIImage? {
        guard !data.isEmpty else { return nil }
        let scale = await MainActor.run { UIScreen.main.scale }
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale

        let srcOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let src = CGImageSourceCreateWithData(data as CFData, srcOptions as CFDictionary) else {
            return nil
        }

        let downOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, downOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }
}
