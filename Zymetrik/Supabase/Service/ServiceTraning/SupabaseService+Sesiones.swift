import Foundation
import Supabase

extension SupabaseService {
    // MARK: - DTO del RPC
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
        let _autor: UUID
    }

    /// Obtiene las sesiones para un ejercicio filtradas por autor.
    /// - Si `autorId` es nil, usa el usuario autenticado.
    func obtenerSesionesPara(ejercicioID: UUID, autorId: UUID? = nil) async throws -> [SesionEjercicio] {
        // Resuelve autor
        let resolvedAuthor: UUID = try await {
            if let autorId { return autorId }
            return try await client.auth.session.user.id
        }()

        let res = try await client
            .rpc(
                "api_get_sesiones",
                params: GetSesionesParams(_ejercicio: ejercicioID, _autor: resolvedAuthor)
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

enum ISO8601 {
    static let zFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return df
    }()
}

extension Date {
    func startOfDayUTC() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = cal.dateComponents([.year,.month,.day], from: self)
        return cal.date(from: comps)!
    }
}
