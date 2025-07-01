import Foundation

struct ChatPreview: Identifiable {
    let id: UUID
    let nombre: String
    let avatarURL: String?
    let ultimoMensaje: String
    let horaUltimoMensaje: String
    let receptorUsername: String
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isCurrentUser: Bool
    let time: String
}
