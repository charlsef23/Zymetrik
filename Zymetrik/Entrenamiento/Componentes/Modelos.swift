import SwiftUI
import Foundation

extension Date {
    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct Ejercicio: Identifiable {
    let id = UUID()
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: TipoEjercicio
}

enum TipoEjercicio: String, CaseIterable {
    case gimnasio = "Gimnasio"
    case cardio = "Cardio"
}
