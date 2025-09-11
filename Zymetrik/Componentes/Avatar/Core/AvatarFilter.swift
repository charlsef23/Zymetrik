import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum AvatarFilter: String, CaseIterable {
    case none = "none"
    case blur = "blur"
    case sepia = "sepia"
    case noir = "noir"
    case vintage = "vintage"
    case vibrant = "vibrant"
    case cool = "cool"
    case warm = "warm"
    
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
    
    func apply(to image: UIImage) -> UIImage {
        guard self != .none,
              let ciImage = CIImage(image: image) else {
            return image
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        switch self {
        case .none:
            break
            
        case .blur:
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.inputImage = ciImage
            blurFilter.radius = 2.0
            outputImage = blurFilter.outputImage ?? ciImage
            
        case .sepia:
            let sepiaFilter = CIFilter.sepiaTone()
            sepiaFilter.inputImage = ciImage
            sepiaFilter.intensity = 0.8
            outputImage = sepiaFilter.outputImage ?? ciImage
            
        case .noir:
            let noirFilter = CIFilter.photoEffectNoir()
            noirFilter.inputImage = ciImage
            outputImage = noirFilter.outputImage ?? ciImage
            
        case .vintage:
            let vintageFilter = CIFilter.photoEffectInstant()
            vintageFilter.inputImage = ciImage
            outputImage = vintageFilter.outputImage ?? ciImage
            
        case .vibrant:
            let vibranceFilter = CIFilter.vibrance()
            vibranceFilter.inputImage = ciImage
            vibranceFilter.amount = 1.0
            outputImage = vibranceFilter.outputImage ?? ciImage
            
        case .cool:
            let temperatureFilter = CIFilter.temperatureAndTint()
            temperatureFilter.inputImage = ciImage
            temperatureFilter.neutral = CIVector(x: 6500, y: 0)
            temperatureFilter.targetNeutral = CIVector(x: 7000, y: -200)
            outputImage = temperatureFilter.outputImage ?? ciImage
            
        case .warm:
            let temperatureFilter = CIFilter.temperatureAndTint()
            temperatureFilter.inputImage = ciImage
            temperatureFilter.neutral = CIVector(x: 6500, y: 0)
            temperatureFilter.targetNeutral = CIVector(x: 5500, y: 200)
            outputImage = temperatureFilter.outputImage ?? ciImage
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
}
