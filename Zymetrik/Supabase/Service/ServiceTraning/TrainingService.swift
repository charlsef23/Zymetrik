import Foundation
import Supabase

// MARK: - Modelos de entrenamiento y ejercicios

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

// MARK: - Publicar entrenamiento (post con contenido de ejercicios)

extension SupabaseService {
    func publicarEntrenamiento(
        fecha: Date,
        ejercicios: [Ejercicio],
        setsPorEjercicio: [UUID: [SetRegistro]]
    ) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        // Normaliza a inicio de día UTC y formatea a ISO Z
        let fechaUTC = fecha.startOfDayUTC()
        let fechaISOZ = ISO8601.zFormatter.string(from: fechaUTC)

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

extension SupabaseService {
    func upsertPlan(fecha: Date, ejercicios: [Ejercicio]) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        struct PlanRow: Encodable {
            let autor_id: UUID
            let fecha: String   // yyyy-MM-dd (UTC)
            let ejercicios: [Ejercicio]
        }

        // Formatter estable en UTC (evita problemas por zona horaria/DST)
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        // Normaliza a inicio del día en UTC
        let onlyDayUTC: Date = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            let comps = cal.dateComponents([.year, .month, .day], from: fecha)
            return cal.date(from: comps)!
        }()

        let row = PlanRow(
            autor_id: userId,
            fecha: df.string(from: onlyDayUTC),
            ejercicios: ejercicios
        )

        // upsert con onConflict en la PK compuesta
        _ = try await client
            .from("entrenamientos_planeados")
            .upsert(row, onConflict: "autor_id,fecha")
            .select() // fuerza ejecución y devuelve fila (opcional)
            .execute()
    }

    func fetchPlan(fecha: Date) async throws -> [Ejercicio] {
        let user = try await client.auth.session.user
        let userId = user.id

        // Formatter UTC consistente
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        // Inicio del día en UTC
        let dayKey: String = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            let comps = cal.dateComponents([.year, .month, .day], from: fecha)
            let start = cal.date(from: comps)!
            return df.string(from: start)
        }()

        struct PlanRowDec: Decodable { let ejercicios: [Ejercicio] }

        do {
            let r: PlanRowDec = try await client
                .from("entrenamientos_planeados")
                .select("ejercicios")
                .eq("autor_id", value: userId.uuidString)
                .eq("fecha", value: dayKey)
                .single() // exactamente una fila
                .execute()
                .decoded(to: PlanRowDec.self)

            return r.ejercicios
        } catch let e as PostgrestError {
            // Si no existe el plan para ese día, devuelve lista vacía
            if e.code == "PGRST116" || e.message.localizedCaseInsensitiveContains("No rows")
               || e.message.localizedCaseInsensitiveContains("Results contain 0 rows") {
                return []
            }
            throw e
        } catch {
            throw error
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
