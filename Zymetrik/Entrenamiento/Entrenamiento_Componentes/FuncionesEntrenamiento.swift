import SwiftUI
import Foundation

enum ProgresoEstado {
    case mejorado, igual, empeorado
}

func compararProgreso(_ sesiones: [SesionEjercicio]) -> ProgresoEstado {
    guard sesiones.count >= 2 else { return .igual }

    let penultimo = sesiones[sesiones.count - 2].pesoTotal
    let ultimo = sesiones.last!.pesoTotal

    if ultimo > penultimo { return .mejorado }
    if ultimo < penultimo { return .empeorado }
    return .igual
}

extension Date {
    func isInLast(seconds: TimeInterval) -> Bool {
        return self >= Date().addingTimeInterval(-seconds)
    }
}
