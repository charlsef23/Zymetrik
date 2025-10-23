import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageCropper {
    static func smartCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let base = image.normalizedUp()
        if let faceRect = detectFace(in: base) {
            return cropToFace(base, faceRect: faceRect, targetSize: targetSize)
        }
        return centerCrop(base, to: targetSize)
    }

    static func centerSquare(_ image: UIImage, size: CGFloat = 400) -> UIImage {
        let base = image.normalizedUp()
        return centerCrop(base, to: .init(width: size, height: size))
    }

    private static func detectFace(in image: UIImage) -> CGRect? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let faces = detector?.features(in: ciImage, options: [CIDetectorImageOrientation: 1]) as? [CIFaceFeature]
        return faces?.first?.bounds
    }

    private static func cropToFace(_ image: UIImage, faceRect: CGRect, targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let scale = image.scale
        // Convertir coordenadas CI -> UIKit
        let convertedRect = CGRect(
            x: faceRect.origin.x,
            y: imageSize.height - faceRect.origin.y - faceRect.height,
            width: faceRect.width,
            height: faceRect.height
        )
        let expanded = convertedRect.insetBy(dx: -convertedRect.width * 0.3, dy: -convertedRect.height * 0.3)
        let crop = CGRect(
            x: max(0, expanded.origin.x) * scale,
            y: max(0, expanded.origin.y) * scale,
            width: min(imageSize.width - expanded.origin.x, expanded.width) * scale,
            height: min(imageSize.height - expanded.origin.y, expanded.height) * scale
        )
        guard let cg = image.cgImage?.cropping(to: crop.integral) else {
            return centerCrop(image, to: targetSize)
        }
        let cropped = UIImage(cgImage: cg, scale: scale, orientation: .up)
        return resizeImage(cropped, to: targetSize)
    }

    private static func centerCrop(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let imageSize = image.size
        let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let scaled = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: (targetSize.width - scaled.width) / 2,
            y: (targetSize.height - scaled.height) / 2,
            width: scaled.width, height: scaled.height
        )
        return renderer.image { _ in image.draw(in: drawRect) }
    }

    private static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: targetSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
