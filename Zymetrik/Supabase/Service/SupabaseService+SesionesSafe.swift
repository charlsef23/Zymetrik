import Foundation
import Supabase

// Caché en memoria simple (TTL 60s) para suavizar picos de RPC
actor SesionesCache {
    static let shared = SesionesCache()
    private var store: [String: [SesionEjercicio]] = [:] // key = "\(autorId.uuidString)|\(ejercicioID.uuidString)"
    private var last: [String: Date] = [:]
    private let ttl: TimeInterval = 60

    func get(key: String) -> [SesionEjercicio]? {
        if let t = last[key], Date().timeIntervalSince(t) < ttl { return store[key] }
        return nil
    }
    func set(key: String, value: [SesionEjercicio]) {
        store[key] = value
        last[key] = Date()
    }
}

extension SupabaseService {
    /// Igual que `obtenerSesionesPara`, pero **no lanza** si la Task fue cancelada (URLError.cancelled o CancellationError).
    func obtenerSesionesParaSafe(ejercicioID: UUID, autorId: UUID? = nil) async -> [SesionEjercicio] {
        do {
            return try await obtenerSesionesPara(ejercicioID: ejercicioID, autorId: autorId)
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled { return [] }
            if error is CancellationError { return [] }
            print("⚠️ obtenerSesionesParaSafe error no crítico: \(error)")
            return []
        }
    }

    /// Versión cacheada por 60s (autor obligatorio para clave estable)
    func obtenerSesionesParaCached(ejercicioID: UUID, autorId: UUID) async -> [SesionEjercicio] {
        let key = "\(autorId.uuidString)|\(ejercicioID.uuidString)"
        if let cached = await SesionesCache.shared.get(key: key) { return cached }
        let fresh = await obtenerSesionesParaSafe(ejercicioID: ejercicioID, autorId: autorId)
        await SesionesCache.shared.set(key: key, value: fresh)
        return fresh
    }
}
