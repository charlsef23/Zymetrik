import SwiftUI

struct AvatarConstants {
    static let extraSmall: CGFloat = 24
    static let small: CGFloat = 32
    static let medium: CGFloat = 56
    static let large: CGFloat = 84
    static let extraLarge: CGFloat = 120
    static let jumbo: CGFloat = 200

    static let compressionQuality: CGFloat = 0.8
    static let maxImageSize: CGFloat = 400
    static let borderWidth: CGFloat = 2

    static let quickAnimation: Double = 0.2
    static let standardAnimation: Double = 0.3
    static let slowAnimation: Double = 0.5

    struct Colors {
        static let borderDefault = Color.white
        static let borderSelected = Color.blue
        static let backgroundFallback = Color(.systemGray5)
        static let gradientPrimary = Color.blue.opacity(0.7)
        static let gradientSecondary = Color.purple.opacity(0.7)
    }

    struct Cache {
        static let memoryLimit = 100
        static let diskLimit = 50 * 1024 * 1024 // 50MB
        static let maxAge: TimeInterval = 7 * 24 * 60 * 60
    }
}
