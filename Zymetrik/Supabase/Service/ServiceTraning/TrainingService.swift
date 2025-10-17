import Foundation
import Supabase

// MARK: - Modelos de entrenamiento y ejercicios

struct EjercicioPostContenido: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let subtipo: String?
    let imagen_url: String?
    let sets: [SetPost]

    var totalSeries: Int { sets.count }
    var totalRepeticiones: Int { sets.reduce(0) { $0 + $1.repeticiones } }
    var totalPeso: Double { sets.reduce(0) { $0 + (Double($1.repeticiones) * $1.peso) } }

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

struct Ejercicio: Identifiable, Codable {
    let id: UUID
    let nombre: String
    let descripcion: String
    let categoria: String
    let tipo: String
    let subtipo: String?
    let imagen_url: String?

    var esFavorito: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, nombre, descripcion, categoria, tipo, subtipo, imagen_url
    }
}


// MARK: - Publicar entrenamiento (post con contenido de ejercicios)

extension SupabaseService {
    func publicarEntrenamiento(
        fecha: Date,
        ejercicios: [Ejercicio],
        setsPorEjercicio: [UUID: [SetRegistro]]
    ) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        // Usa el instante actual (UTC) para la fecha del post, para que aparezca como "recién publicado"
        let nowUTC = Date()
        let fechaISOZ = ISO8601.zFormatter.string(from: nowUTC)

        var ejerciciosContenido: [EjercicioPostContenido] = []
        for ejercicio in ejercicios {
            let setsSrc = setsPorEjercicio[ejercicio.id] ?? []
            let sets = setsSrc
                .filter { $0.repeticiones > 0 || $0.peso > 0 }
                .map { SetPost(repeticiones: $0.repeticiones, peso: $0.peso) }
            guard !sets.isEmpty else { continue }
            ejerciciosContenido.append(
                EjercicioPostContenido(
                    id: ejercicio.id,
                    nombre: ejercicio.nombre,
                    descripcion: ejercicio.descripcion,
                    categoria: ejercicio.categoria,
                    tipo: ejercicio.tipo,
                    subtipo: ejercicio.subtipo,
                    imagen_url: ejercicio.imagen_url,
                    sets: sets
                )
            )
        }
        guard !ejerciciosContenido.isEmpty else {
            throw NSError(domain: "publicarEntrenamiento", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "No hay sets válidos para publicar."])
        }

        struct PerfilLigero: Decodable {
            let id: UUID
            let username: String
            let avatar_url: String?
        }
        let perfil: PerfilLigero = try await client
            .from("perfil")
            .select("id, username, avatar_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .decoded(to: PerfilLigero.self)

        struct PostNuevo: Encodable {
            let autor_id: UUID
            let fecha: String           // ISO8601 Z -> timestamptz
            let avatar_url: String?
            let username: String
            let contenido: [EjercicioPostContenido]
        }

        let post = PostNuevo(
            autor_id: userId,
            fecha: fechaISOZ,
            avatar_url: perfil.avatar_url,
            username: perfil.username,
            contenido: ejerciciosContenido
        )

        try await client.from("posts").insert(post).execute()
    }
}

// MARK: - Planes (upsert/fetch entrenamientos_planeados)

final class SetRegistro: Identifiable, ObservableObject {
    let id: UUID
    var numero: Int
    @Published var repeticiones: Int
    @Published var peso: Double

    init(id: UUID = UUID(), numero: Int, repeticiones: Int, peso: Double) {
        self.id = id
        self.numero = numero
        self.repeticiones = repeticiones
        self.peso = peso
    }
}

extension SupabaseService {
    /// Inserta/actualiza el plan del día (fecha LOCAL -> yyyy-MM-dd)
    func upsertPlan(fecha: Date, ejercicios: [Ejercicio]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        struct PlanRow: Encodable {
            let autor_id: UUID
            let fecha: String   // yyyy-MM-dd (LOCAL)
            let ejercicios: [Ejercicio]
        }

        // Formatter LOCAL consistente
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current                 // LOCAL
        df.dateFormat = "yyyy-MM-dd"

        // Inicio del día LOCAL
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: fecha)
        let localDay = cal.date(from: comps)!
        let dayKey = df.string(from: localDay)

        let row = PlanRow(
            autor_id: userId,
            fecha: dayKey,
            ejercicios: ejercicios
        )

        do {
            _ = try await client
                .from("entrenamientos_planeados")
                .upsert(row, onConflict: "autor_id,fecha")
                .select()
                .execute()
        } catch {
            let nsErr = error as NSError
            // Si usas debounce y cancela la request de URLSession
            if nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorCancelled {
                return
            }
            throw error
        }
    }

    /// Lee el plan del día (clave LOCAL yyyy-MM-dd)
    func fetchPlan(fecha: Date) async throws -> [Ejercicio] {
        let user = try await client.auth.session.user
        let userId = user.id

        // Formatter LOCAL
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: fecha)
        let start = cal.date(from: comps)!
        let dayKey = df.string(from: start)

        struct PlanRowDec: Decodable { let ejercicios: [Ejercicio] }

        do {
            let r: PlanRowDec = try await client
                .from("entrenamientos_planeados")
                .select("ejercicios")
                .eq("autor_id", value: userId.uuidString)
                .eq("fecha", value: dayKey)
                .single()
                .execute()
                .decoded(to: PlanRowDec.self)

            return r.ejercicios
        } catch let e as PostgrestError {
            // Si no existe el plan para ese día, devuelve lista vacía
            if e.code == "PGRST116"
                || e.message.localizedCaseInsensitiveContains("No rows")
                || e.message.localizedCaseInsensitiveContains("Results contain 0 rows") {
                return []
            }
            throw e
        }
    }
}

// MARK: - Favoritos de ejercicios

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
            .eq("autor_id", value: userId.uuidString)
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
            .eq("autor_id", value: userId.uuidString)
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
                .eq("autor_id", value: userId.uuidString)
                .eq("ejercicio_id", value: ejercicioID.uuidString)
                .execute()
        }
    }
}

// MARK: - Posts del usuario (por si lo usas)

extension SupabaseService {
    func fetchPostsDelUsuario(autorId: UUID? = nil) async throws -> [Post] {
        var query = client
            .from("posts")
            .select("""
                id, fecha, autor_id, avatar_url, username, contenido, likes_count, comments_count
            """, head: false)

        if let autorId {
            query = query.eq("autor_id", value: autorId.uuidString)
        } else {
            let user = try await client.auth.session.user
            query = query.eq("autor_id", value: user.id.uuidString)
        }

        let response = try await query
            .order("fecha", ascending: false)
            .execute()

        return try response.decodedList(to: Post.self)
    }
}

// MARK: - RPC: eliminar futuros

struct DeleteFutureResult: Decodable {
    let deleted_plans: Int?
    let deleted_routine_days: Int?
    let canceled_routines: Int?
}

extension SupabaseService {
    /// Llama a la RPC `api_delete_future_workouts` y devuelve el resumen (opcional).
    func deleteFutureWorkouts() async throws -> DeleteFutureResult? {
        let rows: [DeleteFutureResult] = try await SupabaseManager.shared.client
            .rpc("api_delete_future_workouts")
            .execute()
            .decodedList(to: DeleteFutureResult.self)

        return rows.first
    }
}

