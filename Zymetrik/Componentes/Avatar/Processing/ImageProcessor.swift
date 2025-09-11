import UIKit
import CoreImage

class ImageProcessor {
    private let context = CIContext()
    
    func adjustImage(
        _ image: UIImage,
        brightness: Double = 0,
        contrast: Double = 1,
        saturation: Double = 1
    ) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let adjustments = CIFilter.colorControls()
        adjustments.inputImage = ciImage
        adjustments.brightness = Float(brightness)
        adjustments.contrast = Float(contrast)
        adjustments.saturation = Float(saturation)
        
        guard let outputImage = adjustments.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    func applyMultipleFilters(_ image: UIImage, filters: [AvatarFilter]) -> UIImage {
        var processedImage = image
        
        for filter in filters {
            processedImage = filter.apply(to: processedImage)
        }
        
        return processedImage
    }
}
