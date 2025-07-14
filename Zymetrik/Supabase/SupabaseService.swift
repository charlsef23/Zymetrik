import Foundation
import Supabase

struct SupabaseService {
    static let shared = SupabaseService()
    let client = SupabaseManager.shared.client

    // Feed de posts
    func fetchEntrenamientoPost(id: UUID) async throws -> EntrenamientoPost {
        try await client
            .from("posts")
            .select()
            .eq("post_id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchFeedPosts() async throws -> [EntrenamientoPost] {
        try await client
            .from("posts")
            .select()
            .order("fecha", ascending: false)
            .limit(20)
            .execute()
            .value
    }

    // Chat
    func fetchChatPreviews() async throws -> [ChatPreview] {
        let userID = try await client.auth.session.user.id.uuidString

        let response = try await client
            .from("chat_miembros")
            .select("chat_id")
            .eq("autor_id", value: userID)
            .execute()

        let miembros = try response.decoded(to: [ChatMiembro].self)
        let chatIDs = miembros.compactMap { UUID(uuidString: $0.chat_id) }
        var previews: [ChatPreview] = []

        for chatID in chatIDs {
            let otrosResponse = try await client
                .from("chat_miembros")
                .select("autor_id")
                .eq("chat_id", value: chatID.uuidString)
                .neq("autor_id", value: userID)
                .execute()

            let otros = try otrosResponse.decoded(to: [[String: String]].self)
            guard let otroID = otros.first?["autor_id"] else { continue }

            let perfilResponse = try await client
                .from("perfil")
                .select("username, avatar_url")
                .eq("id", value: otroID)
                .single()
                .execute()

            let perfil = try perfilResponse.decoded(to: Perfil.self)

            let mensajesResponse = try await client
                .from("mensajes")
                .select("contenido, enviado_en")
                .eq("chat_id", value: chatID.uuidString)
                .order("enviado_en", ascending: false)
                .limit(1)
                .execute()

            let mensajes = try mensajesResponse.decoded(to: [[String: String]].self)
            let ultimoMensaje = mensajes.first?["contenido"] ?? "Sin mensajes"
            let hora = mensajes.first?["enviado_en"]?.prefix(5) ?? "--:--"

            previews.append(ChatPreview(
                id: chatID,
                nombre: perfil.username,
                avatarURL: perfil.avatar_url,
                ultimoMensaje: ultimoMensaje,
                horaUltimoMensaje: String(hora),
                receptorUsername: perfil.username
            ))
        }

        return previews
    }

    func fetchMensajes(chatID: UUID) async throws -> [ChatMessage] {
        let userID = try await client.auth.session.user.id.uuidString

        let response = try await client
            .from("mensajes")
            .select("id, contenido, autor_id, enviado_en")
            .eq("chat_id", value: chatID.uuidString)
            .order("enviado_en", ascending: true)
            .execute()

        let mensajesDB = try response.decoded(to: [MensajeDB].self)

        return mensajesDB.compactMap { mensaje in
            guard let id = UUID(uuidString: mensaje.id) else { return nil }
            return ChatMessage(
                id: id,
                text: mensaje.contenido,
                isCurrentUser: (mensaje.autor_id == userID),
                time: String(mensaje.enviado_en.prefix(5))
            )
        }
    }

    func enviarMensaje(chatID: UUID, contenido: String) async throws -> ChatMessage {
        let userID = try await client.auth.session.user.id
        let nuevo = NuevoMensaje(chat_id: chatID, autor_id: userID, contenido: contenido)

        let response = try await client
            .from("mensajes")
            .insert(nuevo)
            .select("id, enviado_en")
            .single()
            .execute()

        let mensaje = try response.decoded(to: MensajeDB.self)

        guard let id = UUID(uuidString: mensaje.id) else {
            throw URLError(.badServerResponse)
        }

        return ChatMessage(
            id: id,
            text: contenido,
            isCurrentUser: true,
            time: String(mensaje.enviado_en.prefix(5))
        )
    }

    // Entrenamientos
    func publicarEntrenamiento(fecha: Date, ejercicios: [Ejercicio], setsPorEjercicio: [UUID: [SetRegistro]]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id
        let entrenamientoId = UUID()
        let fechaISO = fecha.formatted(.iso8601)

        let entrenamiento = NuevoEntrenamiento(id: entrenamientoId, autor_id: userId, fecha: fechaISO)
        try await client.from("entrenamientos").insert(entrenamiento).execute()

        let relaciones = ejercicios.map {
            EjercicioEnEntrenamiento(id: UUID(), entrenamiento_id: entrenamientoId, ejercicio_id: $0.id)
        }
        try await client.from("ejercicios_en_entrenamiento").insert(relaciones).execute()

        var sets: [NuevoSet] = []
        for (ejercicioID, setsEjercicio) in setsPorEjercicio {
            for (index, set) in setsEjercicio.enumerated() {
                sets.append(NuevoSet(
                    id: UUID(),
                    entrenamiento_id: entrenamientoId,
                    ejercicio_id: ejercicioID,
                    repeticiones: set.repeticiones,
                    peso: set.peso,
                    orden: index + 1
                ))
            }
        }
        try await client.from("sets").insert(sets).execute()

        let postId = UUID()
        let perfil = try await client
            .from("perfil")
            .select("avatar_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .decoded(to: Perfil.self)

        let post = [
            "id": postId.uuidString,
            "entrenamiento_id": entrenamientoId.uuidString,
            "autor_id": userId.uuidString,
            "avatar_url": perfil.avatar_url ?? ""
        ]
        try await client.from("posts").insert(post).execute()
    }
}

// MARK: - Modelos
struct ChatMiembro: Decodable {
    let chat_id: String
}

struct Perfil: Identifiable, Codable, Equatable {
    let id: UUID
    let username: String
    let nombre: String
    let avatar_url: String?
}


struct MensajeDB: Decodable {
    let id: String
    let contenido: String
    let autor_id: String
    let enviado_en: String
}

struct NuevoMensaje: Codable {
    let chat_id: UUID
    let autor_id: UUID
    let contenido: String
}

struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let imagen_url: String?

    var esFavorito: Bool = false 
}

struct Entrenamiento: Identifiable {
    let id: UUID
    let fecha: Date
}

struct NuevoEntrenamiento: Encodable {
    let id: UUID
    let autor_id: UUID
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

struct NuevoSet: Encodable {
    let id: UUID
    let entrenamiento_id: UUID
    let ejercicio_id: UUID
    let repeticiones: Int
    let peso: Double
    let orden: Int
}

struct EntrenamientoPost: Identifiable, Decodable {
    let id: UUID
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

enum PerfilTab: String, CaseIterable {
    case entrenamientos = "Entrenos"
    case estadisticas = "Estadísticas"
    case logros = "Logros"
}

// MARK: - Helpers
extension PostgrestResponse {
    func decoded<U: Decodable>(to type: U.Type) throws -> U {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(U.self, from: self.data)
    }

    func decodedList<U: Decodable>(to type: U.Type) throws -> [U] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([U].self, from: self.data)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
