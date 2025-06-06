import SwiftUI
import Foundation

enum TipoEjercicio: String {
    case fuerza
    case cardio
}

struct SetEjercicio: Identifiable {
    let id = UUID()
    var peso: String = ""
    var repeticiones: String = ""
    var tiempo: String = ""
    var distancia: String = ""
}

struct EjercicioEntrenamiento: Identifiable {
    let id = UUID()
    var nombre: String
    var tipo: TipoEjercicio
    var sets: [SetEjercicio]
}

struct Ejercicio: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var nombre: String
    var series: Int
    var repeticiones: Int
    var peso: Int

    init(id: UUID = UUID(), nombre: String, series: Int, repeticiones: Int, peso: Int) {
        self.id = id
        self.nombre = nombre
        self.series = series
        self.repeticiones = repeticiones
        self.peso = peso
    }
}

extension Date {
    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct SesionEntrenamiento: Identifiable {
    let id = UUID()
    var titulo: String
    var fecha: Date
    var ejercicios: [EjercicioEntrenamiento]
}

struct Entrenamiento: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var fecha: Date
    var ejercicios: [Ejercicio]
    var notas: String?
}
