import SwiftUI

struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let imagen_url: String?
}

struct Entrenamiento: Identifiable {
    let id: UUID
    let fecha: Date
}


struct NuevoEntrenamiento: Encodable {
    let id: UUID
    let user_id: UUID
    let fecha: String
}

struct EjercicioEnEntrenamiento: Encodable {
    let id: UUID
    let entrenamiento_id: UUID
    let ejercicio_id: UUID
}
