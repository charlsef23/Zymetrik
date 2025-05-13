import Foundation

enum PerfilTab: String, CaseIterable {
    case entrenamientos = "Entrenos"
    case estadisticas = "Estadísticas"
    case logros = "Logros"
}

struct Logro: Identifiable {
    let id = UUID()
    let titulo: String
    let descripcion: String
    let icono: String
}
