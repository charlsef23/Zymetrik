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

    var totalSeries: Int { sets.count }
    var totalRepeticiones: Int { sets.reduce(0) { $0 + $1.repeticiones } }
    var totalPeso: Double { sets.reduce(0) { $0 + $1.peso } }
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

// MARK: - Helpers (decodificador flexible de fechas)

// Contenedor no genérico para poder tener una estática almacenada
fileprivate enum _SupabaseDecoders {
    static let flexible: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            // 1) ISO8601 con fracciones
            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
            if let d = isoFrac.date(from: raw) { return d }

            // 2) ISO8601 sin fracciones
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
            if let d = iso.date(from: raw) { return d }

            // 3) Fallbacks RFC3339 comunes
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
                "yyyy-MM-dd HH:mm:ssXXXXX"
            ]
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.calendar = Calendar(identifier: .iso8601)

            for f in formats {
                df.dateFormat = f
                if let d = df.date(from: raw) { return d }
            }

            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Unsupported date format: \(raw)")
        }
        return decoder
    }()
}

extension PostgrestResponse {
    func decoded<U: Decodable>(to type: U.Type) throws -> U {
        try _SupabaseDecoders.flexible.decode(U.self, from: self.data)
    }

    func decodedList<U: Decodable>(to type: U.Type) throws -> [U] {
        try _SupabaseDecoders.flexible.decode([U].self, from: self.data)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Eliminar post
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

// MARK: - Sesiones por ejercicio (RPC api_get_sesiones)
extension SupabaseService {
    struct SesionPorPostDTO: Decodable {
        let post_id: UUID
        let fecha: String            // "YYYY-MM-DD"
        let ejercicio_id: UUID
        let sets_count: Int
        let repeticiones_total: Int
        let peso_total: Double
    }

    private struct GetSesionesParams: Encodable {
        let _ejercicio: UUID
        let _autor: UUID?
    }

    func obtenerSesionesPara(ejercicioID: UUID, autorId: UUID? = nil) async throws -> [SesionEjercicio] {
        let res = try await client
            .rpc(
                "api_get_sesiones",
                params: GetSesionesParams(_ejercicio: ejercicioID, _autor: autorId)
            )
            .execute()

        let dtos: [SesionPorPostDTO] = try res.decodedList(to: SesionPorPostDTO.self)

        let df = DateFormatter()
        df.calendar = .init(identifier: .iso8601)
        df.locale = .init(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"

        let sesiones: [SesionEjercicio] = dtos.compactMap { dto in
            guard let d = df.date(from: dto.fecha) else { return nil }
            return SesionEjercicio(fecha: d, pesoTotal: dto.peso_total)
        }

        return sesiones.sorted { $0.fecha < $1.fecha }
    }
}

// MARK: - Planes (upsert/fetch)
extension SupabaseService {
    func upsertPlan(fecha: Date, ejercicios: [Ejercicio]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        struct PlanRow: Encodable {
            let autor_id: UUID
            let fecha: String   // yyyy-MM-dd
            let ejercicios: [Ejercicio]
        }

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let row = PlanRow(autor_id: userId, fecha: df.string(from: fecha.stripTime()), ejercicios: ejercicios)

        try await client
            .from("entrenamientos_planeados")
            .upsert(row, onConflict: "autor_id,fecha")
            .execute()
    }

    func fetchPlan(fecha: Date) async throws -> [Ejercicio] {
        let user = try await client.auth.session.user
        let userId = user.id
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let day = df.string(from: fecha.stripTime())

        struct PlanRowDec: Decodable { let ejercicios: [Ejercicio] }

        let res = try await client
            .from("entrenamientos_planeados")
            .select("ejercicios")
            .eq("autor_id", value: userId.uuidString)
            .eq("fecha", value: day)
            .single()
            .execute()
            .decoded(to: PlanRowDec.self)

        return res.ejercicios
    }
}

// MARK: - Favoritos (fetch, toggle, set)
extension SupabaseService {
    func fetchEjerciciosConFavoritos() async throws -> [Ejercicio] {
        let client = self.client
        let userId = try await client.auth.session.user.id

        struct FavoritoID: Decodable { let ejercicio_id: UUID }

        async let ejerciciosReq: [Ejercicio] = client
            .from("ejercicios")
            .select()
            .execute()
            .decodedList(to: Ejercicio.self)

        async let favoritosReq: [FavoritoID] = client
            .from("ejercicios_favoritos")
            .select("ejercicio_id")
            .eq("autor_id", value: userId)
            .execute()
            .decodedList(to: FavoritoID.self)

        let (ejercicios, favoritos) = try await (ejerciciosReq, favoritosReq)
        let favs = Set(favoritos.map(\.ejercicio_id))

        return ejercicios.map { e in
            var copy = e
            copy.esFavorito = favs.contains(e.id)
            return copy
        }
    }

    func fetchFavoritosIDs() async throws -> Set<UUID> {
        let client = self.client
        let userId = try await client.auth.session.user.id

        struct FavoritoID: Decodable { let ejercicio_id: UUID }

        let rows: [FavoritoID] = try await client
            .from("ejercicios_favoritos")
            .select("ejercicio_id")
            .eq("autor_id", value: userId)
            .execute()
            .decodedList(to: FavoritoID.self)

        return Set(rows.map(\.ejercicio_id))
    }

    @discardableResult
    func toggleFavorito(ejercicioID: UUID, currentlyFavorito: Bool) async throws -> Bool {
        try await setFavorito(ejercicioID: ejercicioID, favorito: !currentlyFavorito)
        return !currentlyFavorito
    }

    func setFavorito(ejercicioID: UUID, favorito: Bool) async throws {
        let client = self.client
        let userId = try await client.auth.session.user.id

        if favorito {
            _ = try await client
                .from("ejercicios_favoritos")
                .insert([
                    "autor_id": userId.uuidString,
                    "ejercicio_id": ejercicioID.uuidString
                ])
                .execute()
        } else {
            _ = try await client
                .from("ejercicios_favoritos")
                .delete()
                .eq("autor_id", value: userId)
                .eq("ejercicio_id", value: ejercicioID)
                .execute()
        }
    }
}

// MARK: - Likes
extension SupabaseService {
    func didLike(postID: UUID) async throws -> Bool {
        let userId = try await client.auth.session.user.id
        let res = try await client
            .from("post_likes")
            .select("post_id", head: false)
            .eq("post_id", value: postID.uuidString)
            .eq("autor_id", value: userId.uuidString)
            .limit(1)
            .execute()

        struct Row: Decodable { let post_id: UUID }
        let rows = try res.decodedList(to: Row.self)
        return !rows.isEmpty
    }

    func countLikes(postID: UUID) async throws -> Int {
        let res = try await client
            .from("post_likes")
            .select("post_id", head: true, count: .exact)
            .eq("post_id", value: postID.uuidString)
            .execute()
        return res.count ?? 0
    }

    func setLike(postID: UUID, like: Bool) async throws {
        let userId = try await client.auth.session.user.id

        if like {
            _ = try await client
                .from("post_likes")
                .upsert([
                    "post_id": postID.uuidString,
                    "autor_id": userId.uuidString
                ], onConflict: "post_id,autor_id")
                .execute()
        } else {
            _ = try await client
                .from("post_likes")
                .delete()
                .eq("post_id", value: postID.uuidString)
                .eq("autor_id", value: userId.uuidString)
                .execute()
        }
    }

    @discardableResult
    func toggleLike(postID: UUID, currentlyLiked: Bool) async throws -> Bool {
        try await setLike(postID: postID, like: !currentlyLiked)
        return !currentlyLiked
    }
}

// MARK: - Guardados
extension SupabaseService {
    func didSave(postID: UUID) async throws -> Bool {
        let userId = try await client.auth.session.user.id
        let res = try await client
            .from("post_guardados")
            .select("post_id", head: false)
            .eq("post_id", value: postID.uuidString)
            .eq("autor_id", value: userId.uuidString)
            .limit(1)
            .execute()

        struct Row: Decodable { let post_id: UUID }
        let rows = try res.decodedList(to: Row.self)
        return !rows.isEmpty
    }

    func setSaved(postID: UUID, saved: Bool) async throws {
        let userId = try await client.auth.session.user.id

        if saved {
            _ = try await client
                .from("post_guardados")
                .upsert([
                    "post_id": postID.uuidString,
                    "autor_id": userId.uuidString
                ], onConflict: "post_id,autor_id")
                .execute()
        } else {
            _ = try await client
                .from("post_guardados")
                .delete()
                .eq("post_id", value: postID.uuidString)
                .eq("autor_id", value: userId.uuidString)
                .execute()
        }
    }

    @discardableResult
    func toggleSaved(postID: UUID, currentlySaved: Bool) async throws -> Bool {
        try await setSaved(postID: postID, saved: !currentlySaved)
        return !currentlySaved
    }

    /// Devuelve los posts guardados por el usuario actual.
    func fetchSavedPosts() async throws -> [Post] {
        let userId = try await client.auth.session.user.id

        let res = try await client
            .from("post_guardados")
            .select("""
                post_id,
                posts (
                    id, fecha, autor_id, avatar_url, username, contenido
                )
            """, head: false)
            .eq("autor_id", value: userId.uuidString)
            .execute()

        struct SavedRow: Decodable {
            let post_id: UUID
            let posts: Post
        }

        let rows = try res.decodedList(to: SavedRow.self)
        return rows
            .map { $0.posts }
            .sorted { $0.fecha > $1.fecha }
    }
}
