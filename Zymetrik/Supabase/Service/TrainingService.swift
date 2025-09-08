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
    /// Publica un post de entrenamiento con ejercicios/sets.
    /// - Filtra sets vacíos (0 repeticiones y 0 peso).
    /// - Normaliza la fecha al inicio del día (UTC) para coherencia con estadísticas.
    func publicarEntrenamiento(
        fecha: Date,
        ejercicios: [Ejercicio],
        setsPorEjercicio: [UUID: [SetRegistro]]
    ) async throws {
        let user = try await client.auth.session.user
        let userId = user.id

        // Normaliza a "solo día"
        let df = DateFormatter()
        df.calendar = .init(identifier: .iso8601)
        df.locale = .init(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        let fechaSoloDia = df.string(from: dateAtStartOfDayISO8601(fecha))

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
            throw NSError(domain: "publicarEntrenamiento", code: 400, userInfo: [NSLocalizedDescriptionKey: "No hay sets válidos para publicar."])
        }

        let perfil = try await client
            .from("perfil")
            .select("id, username, nombre, avatar_url")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .decoded(to: Perfil.self)

        struct PostNuevo: Encodable {
            let id: UUID
            let autor_id: UUID
            let fecha: String     // yyyy-MM-dd (Postgres lo convertirá a 00:00Z)
            let avatar_url: String?
            let username: String
            let contenido: [EjercicioPostContenido]
        }

        let post = PostNuevo(
            id: UUID(),
            autor_id: userId,
            fecha: fechaSoloDia,
            avatar_url: perfil.avatar_url,
            username: perfil.username,
            contenido: ejerciciosContenido
        )

        try await client.from("posts").insert(post).execute()
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

// MARK: - Planes (upsert/fetch entrenamientos_planeados)

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
        let onlyDay = dateAtStartOfDayISO8601(fecha)
        let row = PlanRow(autor_id: userId, fecha: df.string(from: onlyDay), ejercicios: ejercicios)

        try await client
            .from("entrenamientos_planeados")
            .upsert(row, onConflict: "autor_id,fecha")
            .execute()
    }

    func fetchPlan(fecha: Date) async throws -> [Ejercicio] {
        let user = try await client.auth.session.user
        let userId = user.id
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let day = df.string(from: dateAtStartOfDayISO8601(fecha))

        struct PlanRowDec: Decodable { let ejercicios: [Ejercicio] }

        let r: PlanRowDec = try await client
            .from("entrenamientos_planeados")
            .select("ejercicios")
            .eq("autor_id", value: userId.uuidString)
            .eq("fecha", value: day)
            .single()
            .execute()
            .decoded(to: PlanRowDec.self)

        return r.ejercicios
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
