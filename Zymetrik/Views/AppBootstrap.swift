import Foundation

enum AppBootstrap {
    /// Configura un URLCache generoso y políticas razonables para acelerar cargas repetidas.
    static func configureNetworkingCache(
        memoryMB: Int = 64,
        diskMB: Int = 256
    ) {
        let cache = URLCache(
            memoryCapacity: memoryMB * 1024 * 1024,
            diskCapacity: diskMB * 1024 * 1024,
            diskPath: "zymetrik_urlcache"
        )
        URLCache.shared = cache

        // Si usas URLSession.shared, estos defaults ayudan a no “esperar conectividad”.
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.waitsForConnectivity = false
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 30

        // Nota: no podemos inyectar `cfg` en `URLSession.shared`.
        // Si tienes un `NetworkClient`, crea `URLSession(configuration: cfg)` ahí.
    }
}
