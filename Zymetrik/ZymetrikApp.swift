import SwiftUI

@main
struct ZymetrikApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var subs = SubscriptionStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppBootstrap.configureNetworkingCache()
        _ = NetworkMonitor.shared   // inicia el monitor de red
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subs)
                // Precalienta suscripciones sin bloquear el primer frame
                .task {
                    // Pequeña demora para dejar renderizar la primera pantalla
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    await preloadSubscriptions()
                }
                // Programa actualizaciones “no críticas” de OneSignal cuando ya hay primer frame
                .task {
                    // un pelín más tarde para evitar 'unconnected nw_connection'
                    try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s
                    await OneSignalWrapper.shared.schedulePostLaunchUpdates {
                        // ⚠️ Pon aquí tus operaciones NO críticas de OneSignal:
                        // Ejemplos (ajusta a tu integración real):
                        // OneSignal.login(userId)
                        // OneSignal.User.addTag("app_version", Bundle.main.appVersion)
                        // OneSignal.User.pushSubscription.optIn()
                    }
                }
                // Re-sync cuando la app pasa a activa
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task.detached(priority: .utility) { [subs] in
                            await subs.refresh()
                            // Si quieres, también puedes reintentar OneSignal suave:
                            await OneSignalWrapper.shared.safeUpdate {
                                // p.ej., refrescar tags/props si hiciera falta
                            }
                        }
                    }
                }
        }
    }

    @Sendable
    private func preloadSubscriptions() async {
        // Corre en prioridad baja; cancela limpio si el View se descarta
        await withTaskCancellationHandler {
            await Task.yield() // permite al scheduler priorizar UI
            await subs.loadProducts()
            await subs.refresh()
        } onCancel: {
            // no-op; aquí podrías limpiar si guardas estado intermedio
        }
    }
}
