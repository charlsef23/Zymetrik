import Foundation

extension SupabaseService {
    // Cache simple en memoria
    private static var _logrosCache: [LogroConEstado] = []
    private static var _logrosCacheTimestamp: Date?
    private static let _logrosCacheExpiry: TimeInterval = 300 // 5 min

    /// Obtiene logros usando un cache simple en memoria.
    /// - Parameters:
    ///   - autorId: si se pasa, obtiene logros de ese usuario; si es nil, del autenticado.
    ///   - forceRefresh: ignora el cache y fuerza recarga.
    func fetchLogrosCached(autorId: UUID? = nil, forceRefresh: Bool = false) async throws -> [LogroConEstado] {
        let now = Date()
        if !forceRefresh,
           let ts = Self._logrosCacheTimestamp,
           now.timeIntervalSince(ts) < Self._logrosCacheExpiry,
           !Self._logrosCache.isEmpty {
            return Self._logrosCache
        }

        let fresh: [LogroConEstado]
        if let autorId {
            fresh = try await fetchLogrosCompletos(autorId: autorId)
        } else {
            fresh = try await fetchLogrosCompletos()
        }

        Self._logrosCache = fresh
        Self._logrosCacheTimestamp = now
        return fresh
    }

    /// Invalida el cache de logros (usado tras otorgar nuevos logros).
    func invalidateLogrosCache() {
        Self._logrosCache = []
        Self._logrosCacheTimestamp = nil
    }
}
