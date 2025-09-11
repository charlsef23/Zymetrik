import UIKit
import CoreImage

class ImageCropper {
    static func smartCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        // Detectar rostros y centrar el recorte
        if let faceRect = detectFace(in: image) {
            return cropToFace(image, faceRect: faceRect, targetSize: targetSize)
        }
        
        // Si no hay rostros, usar recorte centrado inteligente
        return centerCrop(image, to: targetSize)
    }
    
    static func cropToSquare(_ image: UIImage, size: CGFloat = 400) -> UIImage {
        let targetSize = CGSize(width: size, height: size)
        return smartCrop(image, to: targetSize)
    }
    
    private static func detectFace(in image: UIImage) -> CGRect? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        
        let faces = detector?.features(in: ciImage) as? [CIFaceFeature]
        return faces?.first?.bounds
    }
    
    private static func cropToFace(_ image: UIImage, faceRect: CGRect, targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let scale = image.scale
        
        // Convertir coordenadas de Core Image a UIKit
        let convertedRect = CGRect(
            x: faceRect.origin.x,
            y: imageSize.height - faceRect.origin.y - faceRect.height,
            width: faceRect.width,
            height: faceRect.height
        )
        
        // Expandir el área alrededor del rostro
        let expandedRect = convertedRect.insetBy(
            dx: -convertedRect.width * 0.3,
            dy: -convertedRect.height * 0.3
        )
        
        let cropRect = CGRect(
            x: max(0, expandedRect.origin.x * scale),
            y: max(0, expandedRect.origin.y * scale),
            width: min(imageSize.width * scale - expandedRect.origin.x * scale, expandedRect.width * scale),
            height: min(imageSize.height * scale - expandedRect.origin.y * scale, expandedRect.height * scale)
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return centerCrop(image, to: targetSize)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
        return resizeImage(croppedImage, to: targetSize)
    }
    
    private static func centerCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        let drawRect = CGRect(
            x: -cropRect.origin.x,
            y: -cropRect.origin.y,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        image.draw(in: drawRect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    private static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
