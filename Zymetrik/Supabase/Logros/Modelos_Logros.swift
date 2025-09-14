import Foundation
import SwiftUI

// MARK: - Modelos principales

struct Logro: Identifiable, Decodable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let icono_nombre: String
    let orden: Int
    let color: String?

    enum CodingKeys: String, CodingKey {
        case id, titulo, descripcion, icono_nombre, orden, color
    }
}

struct LogroUsuario: Decodable {
    let id: UUID?
    let logro_id: UUID
    let autor_id: UUID
    let conseguido_en: Date

    enum CodingKeys: String, CodingKey {
        case id, logro_id, autor_id, conseguido_en
    }
}

struct LogroConEstado: Identifiable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let icono_nombre: String
    let desbloqueado: Bool
    let fecha: Date?
    let color: String?
}
// MARK: - Modelos de respuesta (RPC / estadísticas)

struct AchievementProgressResponse: Decodable {
    let total_workouts: Int
    let total_weight: Double
    let total_likes: Int
    let days_active: Int
}

struct UserRankingResponse: Decodable {
    let achievements_count: Int
    let rank: Int
    let total_users: Int
    let percentile: Double
}

// MARK: - Categorías de logros (ÚNICA definición)

enum LogroCategory: String, CaseIterable {
    case all = "Todos"
    case training = "Entrenamientos"
    case social = "Social"
    case milestones = "Hitos"

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .training: return "dumbbell.fill"
        case .social: return "person.2.fill"
        case .milestones: return "flag.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .training: return .green
        case .social: return .purple
        case .milestones: return .orange
        }
    }
}

// MARK: - Extensiones de ayuda

extension Logro {
    func toLogroConEstado(desbloqueado: Bool = false, fecha: Date? = nil) -> LogroConEstado {
        LogroConEstado(
            id: id,
            titulo: titulo,
            descripcion: descripcion,
            icono_nombre: icono_nombre,
            desbloqueado: desbloqueado,
            fecha: fecha,
            color: color
        )
    }
}

extension LogroConEstado {
    var isRecentlyUnlocked: Bool {
        guard let fecha = fecha else { return false }
        return Date().timeIntervalSince(fecha) < 86_400
    }

    var swiftUIColor: Color? {
        Color.fromHex(color)
    }

    var categoria: LogroCategory {
        switch icono_nombre {
        case "dumbbell.fill", "flame.fill", "trophy.fill":
            return .training
        case "person.2.fill", "heart.fill":
            return .social
        case "calendar.badge.clock", "star.fill", "crown.fill":
            return .milestones
        default:
            return .training
        }
    }
}

// MARK: - Extensiones para fechas

extension Date {
    /// Formato amigable para mostrar fechas de logros
    var achievementDateFormat: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(self) { return "Hoy" }
        if calendar.isDateInYesterday(self) { return "Ayer" }

        if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(self) == true {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        }

        if calendar.dateInterval(of: .year, for: Date())?.contains(self) == true {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: self)
        }

        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: self)
    }
}
