import SwiftUI

struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let imagen_url: String?
}
