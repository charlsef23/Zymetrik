import Foundation

actor OneSignalWrapper {
    static let shared = OneSignalWrapper()

    private var scheduled = false
    private var isUpdating = false

    /// Llamar una vez tras el arranque (por ejemplo desde ZymetrikApp)
    func schedulePostLaunchUpdates(_ work: @escaping @Sendable () async -> Void) {
        guard !scheduled else { return }
        scheduled = true
        Task.detached(priority: .utility) {
            // Espera a que la UI pinte el primer frame
            try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s
            await self.safeUpdate(work: work)
        }
    }

    /// Ejecuta una actualización con reachability + backoff (no reentra)
    func safeUpdate(work: @escaping @Sendable () async -> Void) async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        var delay: UInt64 = 0
        for attempt in 0..<3 {
            if !NetworkMonitor.shared.isReachable {
                // espera pequeña hasta que haya red
                delay = max(delay, 400_000_000) // 0.4s
            }
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }

            // si ya hay conectividad, intenta
            if NetworkMonitor.shared.isReachable {
                await work()
                return
            }
            // backoff exponencial (0.4s, 0.8s, 1.6s)
            delay = (attempt == 0) ? 800_000_000 : delay * 2
        }
        // último intento “fire and forget” aunque el monitor no esté actualizado aún
        await work()
    }
}
