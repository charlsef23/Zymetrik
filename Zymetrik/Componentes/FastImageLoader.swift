import UIKit
import ImageIO
import UniformTypeIdentifiers

enum FastImageLoader {
    /// Descarga con caché y hace downsample al tamaño pedido.
    static func downsampledImage(from url: URL, targetSize: CGSize) async -> UIImage? {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return await downsampledImage(data: data, targetSize: targetSize)
        } catch {
            return nil
        }
    }

    /// Downsample a partir de datos en memoria.
    static func downsampledImage(data: Data, targetSize: CGSize) async -> UIImage? {
        let scale = await MainActor.run { UIScreen.main.scale }
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale

        // kUTTypeJPEG está deprecado → usa UniformTypeIdentifiers
        let srcOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceTypeIdentifierHint: UTType.jpeg.identifier as CFString
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
