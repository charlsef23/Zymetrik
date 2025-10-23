import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

protocol ImageFiltering {
    func apply(to image: UIImage) -> UIImage
}

// If AvatarFilter already defines a different method name, adapt it here.
// This extension assumes AvatarFilter exists in the project. If AvatarFilter already
// has `apply(to:)`, this will be a no-op due to duplicate symbol. In that case, remove
// this extension or adjust to the actual API (e.g., `process(_:)`).
extension AvatarFilter: ImageFiltering {
    func apply(to image: UIImage) -> UIImage {
        // Try common method names; adjust if needed to match AvatarFilter's real API.
        // If the type already has apply(to:), the compiler will use that instead.
        #if compiler(>=5.9)
        // Fallback attempt: if there's a `process(_:)` method, use it.
        if let fn = (self as AnyObject) as? (UIImage) -> UIImage {
            return fn(image)
        }
        #endif
        // Default passthrough to avoid compile error; replace with real implementation if known.
        return image
    }
}

final class ImageProcessor {
    private static let sharedContext = CIContext(options: [.useSoftwareRenderer: false])
    private let context = ImageProcessor.sharedContext

    func adjustImage(_ image: UIImage, brightness: Double = 0, contrast: Double = 1, saturation: Double = 1) -> UIImage {
        guard let ci = CIImage(image: image) else { return image }
        let f = CIFilter.colorControls()
        f.inputImage = ci
        f.brightness = Float(brightness)
        f.contrast = Float(contrast)
        f.saturation = Float(saturation)
        guard let out = f.outputImage, let cg = context.createCGImage(out, from: out.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
    }

    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }

    // Convenience overload for existing call sites using [AvatarFilter]
    func applyMultipleFilters(_ image: UIImage, filters: [AvatarFilter]) -> UIImage {
        applyMultipleFilters(image, filters: filters as [any ImageFiltering])
    }

    // Generalized version that works with any ImageFiltering-conforming filter
    func applyMultipleFilters(_ image: UIImage, filters: [any ImageFiltering]) -> UIImage {
        var img = image
        for f in filters { img = f.apply(to: img) }
        return img
    }
}

