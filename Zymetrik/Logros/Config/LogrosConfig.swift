import Foundation

// MARK: - Configuración global del sistema de logros (ÚNICA)

struct LogrosConfig {

    // Cache
    static let cacheExpirationTime: TimeInterval = 300
    static let maxRecentAchievements = 5
    static let achievementCheckInterval: TimeInterval = 300

    // Animaciones / UI
    static let popupAnimationDuration: Double = 0.8
    static let particleAnimationDuration: Double = 2.0
    static let particleCount = 15
    static let hapticFeedbackEnabled = true
    static let cardAnimationDuration: Double = 0.3

    // Colores por defecto
    static let defaultColors = [
        "verde": "#4CAF50",
        "azul": "#2196F3",
        "naranja": "#FF9800",
        "morado": "#9C27B0",
        "rojo": "#F44336",
        "teal": "#009688",
        "amarillo": "#FFD700",
        "rosa": "#E91E63",
        "gris": "#9E9E9E",
        "verde_claro": "#8BC34A"
    ]

    // Iconos por categoría
    static let categoryIcons = [
        "entrenamiento": "dumbbell.fill",
        "social": "person.2.fill",
        "hito": "flag.fill",
        "tiempo": "clock.fill",
        "peso": "scalemass.fill"
    ]

    // Red
    static let networkTimeout: TimeInterval = 10
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1
}

// MARK: - Extensión dinámica

extension LogrosConfig {
    static func color(for achievement: String) -> String {
        switch achievement.lowercased() {
        case "primer entrenamiento", "primer post": return defaultColors["verde"]!
        case "5 entrenamientos", "sociable": return defaultColors["azul"]!
        case "levanta 1000kg", "popular": return defaultColors["amarillo"]!
        case "constante": return defaultColors["naranja"]!
        case "veterano": return defaultColors["morado"]!
        case "maestro": return defaultColors["gris"]!
        default: return defaultColors["azul"]!
        }
    }
}

// MARK: - Entorno

enum LogrosEnvironment {
    case development, staging, production

    static var current: LogrosEnvironment {
        #if DEBUG
        .development
        #else
        .production
        #endif
    }

    var enableDebugLogs: Bool {
        switch self {
        case .development, .staging: return true
        case .production: return false
        }
    }

    var cacheEnabled: Bool {
        switch self {
        case .development: return false
        case .staging, .production: return true
        }
    }
}
