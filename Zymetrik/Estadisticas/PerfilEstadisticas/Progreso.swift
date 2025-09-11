import Foundation

enum ProgresoEstado {
    case mejorado, igual, empeorado
}

/// Compara las dos últimas sesiones por pesoTotal con tolerancia de 0.1 kg.
func compararProgreso(_ sesiones: [SesionEjercicio]) -> ProgresoEstado {
    let datos = sesiones.sorted { $0.fecha < $1.fecha }
    guard datos.count >= 2 else { return .igual }

    let penultimo = datos[datos.count - 2].pesoTotal
    let ultimo = datos[datos.count - 1].pesoTotal

    if ultimo > penultimo + 0.1 { return .mejorado }
    if abs(ultimo - penultimo) <= 0.1 { return .igual }
    return .empeorado
}
