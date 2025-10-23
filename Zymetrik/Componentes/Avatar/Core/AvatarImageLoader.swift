import UIKit

/// Loader centralizado para avatares: cache (memoria+disco) -> red + downsample.
enum AvatarImageLoader {
    /// Carga avatar con clave de caché = URL absoluta.
    static func load(urlString: String?, targetSide: CGFloat) async -> UIImage? {
        guard let url = urlString?.validHTTPURL else { return nil }
        let cacheKey = url.absoluteString

        if let cached = AvatarCache.shared.getImage(forKey: cacheKey) {
            return cached
        }
        // Descarga + downsampling al tamaño exacto que dibujarás.
        if let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: targetSide, height: targetSide)) {
            AvatarCache.shared.setImage(img, forKey: cacheKey)
            return img
        }
        return nil
    }
}
