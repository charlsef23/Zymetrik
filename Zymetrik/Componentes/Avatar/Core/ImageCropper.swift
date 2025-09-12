import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageCropper {

    static func smartCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        // 1) Normaliza orientación primero
        let base = image.normalizedUp()

        // 2) Detecta rostro en la imagen ya normalizada
        if let faceRect = detectFace(in: base) {
            return cropToFace(base, faceRect: faceRect, targetSize: targetSize)
        }
        return centerCrop(base, to: targetSize)
    }

    /// API pública para desactivar el auto-rostro y hacer recorte centrado
    static func centerSquare(_ image: UIImage, size: CGFloat = 400) -> UIImage {
        let base = image.normalizedUp()
        return centerCrop(base, to: CGSize(width: size, height: size))
    }

    // MARK: - Privado (sin cambios salvo comentarios)

    private static func detectFace(in image: UIImage) -> CGRect? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Con la imagen ya normalizada a .up, la orientación EXIF = 1
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        let opts: [String: Any] = [CIDetectorImageOrientation: 1]
        let faces = detector?.features(in: ciImage, options: opts) as? [CIFaceFeature]
        return faces?.first?.bounds
    }

    private static func cropToFace(_ image: UIImage, faceRect: CGRect, targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let scale = image.scale

        // Core Image coord ↔️ UIKit coord
        let convertedRect = CGRect(
            x: faceRect.origin.x,
            y: imageSize.height - faceRect.origin.y - faceRect.height,
            width: faceRect.width,
            height: faceRect.height
        )

        // Expande alrededor del rostro
        let expandedRect = convertedRect.insetBy(dx: -convertedRect.width * 0.3,
                                                 dy: -convertedRect.height * 0.3)

        let cropRect = CGRect(
            x: max(0, expandedRect.origin.x) * scale,
            y: max(0, expandedRect.origin.y) * scale,
            width: min(imageSize.width - expandedRect.origin.x, expandedRect.width) * scale,
            height: min(imageSize.height - expandedRect.origin.y, expandedRect.height) * scale
        )

        guard let cg = image.cgImage?.cropping(to: cropRect.integral) else {
            return centerCrop(image, to: targetSize)
        }

        let cropped = UIImage(cgImage: cg, scale: scale, orientation: .up)
        return resizeImage(cropped, to: targetSize)
    }

    private static func centerCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)

        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )

        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        let drawRect = CGRect(x: -cropRect.origin.x,
                              y: -cropRect.origin.y,
                              width: scaledSize.width,
                              height: scaledSize.height)
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
