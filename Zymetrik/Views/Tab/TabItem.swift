import SwiftUI

enum TabItem: String, CaseIterable, Hashable, Identifiable {
    case inicio
    case entrenamiento
    case search
    case perfil

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inicio:        return "Inicio"
        case .entrenamiento: return "Entrenamiento"
        case .search:        return "Buscar"
        case .perfil:        return "Perfil"
        }
    }

    var symbol: String {
        switch self {
        case .inicio:        return "house"
        case .entrenamiento: return "dumbbell"
        case .search:        return "magnifyingglass"
        case .perfil:        return "person.crop.circle"
        }
    }
}
