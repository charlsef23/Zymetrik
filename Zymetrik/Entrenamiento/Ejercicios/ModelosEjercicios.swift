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

class SetRegistro: Identifiable, ObservableObject {
    let id: UUID
    let numero: Int
    @Published var repeticiones: Int
    @Published var peso: Double

    init(id: UUID = UUID(), numero: Int, repeticiones: Int, peso: Double) {
        self.id = id
        self.numero = numero
        self.repeticiones = repeticiones
        self.peso = peso
    }
}

struct EntrenamientoPost: Identifiable, Decodable {
    let id: UUID         // <- post_id
    let fecha: Date
    let user_id: UUID
    let username: String
    let avatar_url: String?
    let ejercicios: [EjercicioPost]

    enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case fecha, user_id, username, avatar_url, ejercicios
    }
}

struct EjercicioPost: Identifiable, Decodable {
    let id: UUID
    let nombre: String
    let series: Int
    let repeticiones: Int
    let peso_total: Double
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
