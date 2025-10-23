import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum AvatarFilter: String, CaseIterable {
    case none, blur, sepia, noir, vintage, vibrant, cool, warm

    var displayName: String {
        switch self {
        case .none: return "Original"
        case .blur: return "Desenfoque"
        case .sepia: return "Sepia"
        case .noir: return "Blanco y Negro"
        case .vintage: return "Vintage"
        case .vibrant: return "Vibrante"
        case .cool: return "Frío"
        case .warm: return "Cálido"
        }
    }

    var icon: String {
        switch self {
        case .none: return "circle"
        case .blur: return "camera.filters"
        case .sepia: return "leaf"
        case .noir: return "circle.lefthalf.filled"
        case .vintage: return "camera.viewfinder"
        case .vibrant: return "paintpalette"
        case .cool: return "snowflake"
        case .warm: return "sun.max"
        }
    }
}

/// Contexto compartido + pipeline optimizada (evita crear CIContext por filtro).
enum AvatarFilterService {
    static let shared = AvatarFilterRuntime()
}

final class AvatarFilterRuntime {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func apply(filter: AvatarFilter, to image: UIImage) -> UIImage {
        guard filter != .none, let ciImage = CIImage(image: image) else { return image }

        let outputImage: CIImage?
        switch filter {
        case .none:
            outputImage = ciImage

        case .blur:
            let f = CIFilter.gaussianBlur()
            f.inputImage = ciImage
            f.radius = 2.0
            outputImage = f.outputImage?.clampedToExtent()

        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = ciImage
            f.intensity = 0.8
            outputImage = f.outputImage

        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = ciImage
            outputImage = f.outputImage

        case .vintage:
            let f = CIFilter.photoEffectInstant()
            f.inputImage = ciImage
            outputImage = f.outputImage

        case .vibrant:
            let f = CIFilter.vibrance()
            f.inputImage = ciImage
            f.amount = 1.0
            outputImage = f.outputImage

        case .cool:
            let f = CIFilter.temperatureAndTint()
            f.inputImage = ciImage
            f.neutral = CIVector(x: 6500, y: 0)
            f.targetNeutral = CIVector(x: 7000, y: -200)
            outputImage = f.outputImage

        case .warm:
            let f = CIFilter.temperatureAndTint()
            f.inputImage = ciImage
            f.neutral = CIVector(x: 6500, y: 0)
            f.targetNeutral = CIVector(x: 5500, y: 200)
            outputImage = f.outputImage
        }

        guard let out = outputImage,
              let cg = context.createCGImage(out, from: ciImage.extent)
        else { return image }

        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
    }
}
