import UIKit
import ImageIO
import MobileCoreServices

enum FastImageLoader {
    static func downsampledImage(from url: URL, targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) async -> UIImage? {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return downsampledImage(data: data, targetSize: targetSize, scale: scale)
        } catch {
            return nil
        }
    }

    static func downsampledImage(data: Data, targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * scale
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceTypeIdentifierHint: kUTTypeJPEG,
        ]

        guard let src = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }

        let downsampOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, downsampOptions as CFDictionary) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }
}
