import SwiftUI

extension Color {
    /// Inicializador con string HEX tipo "#RRGGBB" o "RRGGBB".
    init?(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Convierte un opcional HEX a Color opcional.
    static func fromHex(_ hex: String?) -> Color? {
        guard let hex, !hex.isEmpty else { return nil }
        return Color(hex: hex)
    }
    
    /// Colores predefinidos para logros
    static let achievementColors = [
        "green": Color(hex: "#4CAF50"),
        "blue": Color(hex: "#2196F3"),
        "orange": Color(hex: "#FF9800"),
        "purple": Color(hex: "#9C27B0"),
        "red": Color(hex: "#F44336"),
        "teal": Color(hex: "#009688"),
        "yellow": Color(hex: "#FFD700"),
        "pink": Color(hex: "#E91E63")
    ]
}

// MARK: - Extensión para obtener el color complementario

extension Color {
    /// Devuelve un color más oscuro del actual
    func darker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    /// Devuelve un color más claro del actual
    func lighter(by percentage: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(
            UIColor(
                hue: hue,
                saturation: saturation,
                brightness: min(brightness + CGFloat(percentage), 1.0),
                alpha: alpha
            )
        )
    }
}
