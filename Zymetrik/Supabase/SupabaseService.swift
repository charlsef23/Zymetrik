import Foundation
import Supabase

struct SupabaseService {
    static let shared = SupabaseService()
    let client = SupabaseManager.shared.client

    // Feed de posts
    func fetchPosts(id: UUID? = nil, limit: Int = 20) async throws -> [Post] {
        var query = client
            .from("posts")
            .select("""
                id, fecha, autor_id, avatar_url, username, contenido
            """, head: false)

        if let id = id {
            query = query.eq("id", value: id.uuidString)
        }

        let response = try await query
            .order("fecha", ascending: false)
            .limit(limit)
            .execute()

        return try response.decodedList(to: Post.self)
    }

    // Publicar Entrenamiento directo en posts
    func publicarEntrenamiento(fecha: Date, ejercicios: [Ejercicio], setsPorEjercicio: [UUID: [SetRegistro]]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id
        let fechaISO = fecha.formatted(.iso8601)

        print("📌 Preparando publicación directa sin tabla entrenamiento")

        var ejerciciosContenido: [EjercicioPostContenido] = []

        for ejercicio in ejercicios {
            let sets = setsPorEjercicio[ejercicio.id]?.map {
                SetPost(repeticiones: $0.repeticiones, peso: $0.peso)
            } ?? []

            let ejercicioContenido = EjercicioPostContenido(
                id: ejercicio.id,
                nombre: ejercicio.nombre,
                descripcion: ejercicio.descripcion,
                categoria: ejercicio.categoria,
                tipo: ejercicio.tipo,
                imagen_url: ejercicio.imagen_url,
                sets: sets
            )

            ejerciciosContenido.append(ejercicioContenido)
        }

        let perfil = try await client
            .from("perfil")
            .select("id, username, nombre, avatar_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .decoded(to: Perfil.self)

        let post = PostNuevo(
            id: UUID(),
            autor_id: userId,
            fecha: fechaISO,
            avatar_url: perfil.avatar_url,
            username: perfil.username,
            contenido: ejerciciosContenido
        )

        try await client
            .from("posts")
            .insert(post)
            .execute()

        print("✅ Publicación realizada con ejercicios y sets en contenido JSONB")
    }
}

// MARK: - Modelos
struct PostNuevo: Encodable {
    let id: UUID
    let autor_id: UUID
    let fecha: String
    let avatar_url: String?
    let username: String
    let contenido: [EjercicioPostContenido]
}

struct Post: Identifiable, Decodable {
    let id: UUID
    let fecha: Date
    let autor_id: UUID
    let avatar_url: String?
    let username: String
    let contenido: [EjercicioPostContenido]
}

struct EjercicioPostContenido: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let imagen_url: String?
    let sets: [SetPost]

    var totalSeries: Int {
        sets.count
    }

    var totalRepeticiones: Int {
        sets.reduce(0) { $0 + $1.repeticiones }
    }

    var totalPeso: Double {
        sets.reduce(0) { $0 + $1.peso }
    }
}

struct SetPost: Codable {
    let repeticiones: Int
    let peso: Double
}

struct SesionEjercicio: Identifiable {
    let id = UUID()
    let fecha: Date
    let pesoTotal: Double
}

struct Perfil: Identifiable, Codable, Equatable {
    let id: UUID
    let username: String
    let nombre: String
    let avatar_url: String?
}

struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let imagen_url: String?

    var esFavorito: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, nombre, descripcion, categoria, tipo, imagen_url
    }
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

extension SupabaseService {
    func eliminarPost(postID: UUID) async throws {
        _ = try await client
            .from("posts")
            .delete()
            .eq("id", value: postID.uuidString)
            .execute()

        print("✅ Post eliminado correctamente en Supabase")
    }
}

extension SupabaseService {
    func obtenerSesionesPara(ejercicioID: UUID) async throws -> [SesionEjercicio] {
        let response = try await client
            .from("posts")
            .select("fecha, contenido", head: false)
            .order("fecha", ascending: true)
            .execute()

        struct PostConContenido: Decodable {
            let fecha: Date
            let contenido: [EjercicioPostContenido]
        }

        let posts = try response.decodedList(to: PostConContenido.self)

        return posts.compactMap { post in
            guard let ejercicio = post.contenido.first(where: { $0.id == ejercicioID }) else {
                return nil
            }
            return SesionEjercicio(fecha: post.fecha, pesoTotal: ejercicio.totalPeso)
        }
    }
}
