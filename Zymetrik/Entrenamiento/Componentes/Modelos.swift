import SwiftUI
import Foundation

extension Date {
    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct Ejercicio: Identifiable {
    let id = UUID()
    var nombre: String
    var descripcion: String
    var categoria: String
    var tipo: TipoEjercicio
    var esFavorito: Bool = false
}

enum TipoEjercicio: String, CaseIterable {
    case gimnasio, cardio, funcional
}
