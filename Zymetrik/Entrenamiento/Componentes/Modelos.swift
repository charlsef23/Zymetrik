import SwiftUI
import Foundation

extension Date {
    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct Ejercicio: Identifiable, Hashable {
    var id = UUID()
    var nombre: String
    var descripcion: String
    var categoria: String
    var tipo: TipoEjercicio
    var series: Int? = nil
    var repeticionesTotales: Int? = nil
    var pesoTotal: Double? = nil
    var esFavorito: Bool = false
}

enum TipoEjercicio: String, CaseIterable {
    case gimnasio, cardio, funcional
}

struct EntrenamientoPorDia: Identifiable {
    let id = UUID()
    let fecha: Date
    var ejercicios: [Ejercicio]
}

struct Entrenamiento: Identifiable {
    var id = UUID()
    var fecha: Date
    var ejercicios: [Ejercicio]
}

struct EjercicioPost: Hashable {
    let nombre: String
    let series: Int
    let repeticionesTotales: Int
    let pesoTotal: Double
}

struct EntrenamientoPost: Identifiable, Hashable {
    let id = UUID()
    var usuario: String
    var fecha: Date
    var titulo: String
    var ejercicios: [EjercicioPost]
    var mediaURL: URL? // puede ser nil
}
