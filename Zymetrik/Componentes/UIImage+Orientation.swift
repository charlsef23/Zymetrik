import UIKit

extension UIImage {
    /// Renderiza la imagen respetando el `scale` pero forzando orientation `.up`
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }

    /// Rota la imagen 90º * n (0..3)
    func rotated(quarterTurns: Int) -> UIImage {
        let t = ((quarterTurns % 4) + 4) % 4
        guard t != 0 else { return self }

        let radians = CGFloat(t) * .pi / 2
        var newSize = size
        if t % 2 == 1 { newSize = CGSize(width: size.height, height: size.width) }

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return self }

        // Mover origen al centro y rotar
        ctx.translateBy(x: newSize.width/2, y: newSize.height/2)
        ctx.rotate(by: radians)

        // Dibuja con el tamaño original, centrado
        draw(in: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height))

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
