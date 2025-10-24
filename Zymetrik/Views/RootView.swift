import SwiftUI
import Supabase

@MainActor
struct RootView: View {
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    @StateObject private var appState = AppState()
    @StateObject private var contentStore = ContentStore.shared
    @StateObject private var planStore = TrainingPlanStore()
    @StateObject private var uiState = AppUIState()
    @StateObject private var routine = RoutineTracker.shared
    @StateObject private var subs = SubscriptionStore.shared

    // Contadores/bloques
    @StateObject private var blockStore = BlockStore()

    // ⬇️ Stores precargados
    @StateObject private var feedStore = FeedStore.shared
    @StateObject private var statsStore = StatsStore.shared
    @StateObject private var achievementsStore = AchievementsStore.shared

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Cargando…")
            } else if !isLoggedIn {
                WelcomeView {
                    self.isLoggedIn = true
                    appState.phase = .loading(progress: 0, message: "Preparando…")
                }
            } else {
                switch appState.phase {
                case .loading, .error:
                    // Mantén splash mientras se precarga TODO
                    SplashView()
                case .ready:
                    CustomTabContainer()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        // Inyección de dependencias
        .environmentObject(appState)
        .environmentObject(contentStore)
        .environmentObject(planStore)
        .environmentObject(uiState)
        .environmentObject(routine)
        .environmentObject(subs)
        .environmentObject(blockStore)
        .environmentObject(feedStore)
        .environmentObject(statsStore)
        .environmentObject(achievementsStore)
        // Precarga al iniciar sesión
        .task {
            await checkSession()
            if isLoggedIn {
                appState.phase = .loading(progress: 0.1, message: "Preparando…")

                // Ejecuta cargas en paralelo
                async let _subsProducts: Void = subs.loadProducts()
                async let _subsRefresh:  Void = subs.refresh()
                async let _blocks:       Void = blockStore.reload()

                // Feed completo (Para ti / Siguiendo)
                async let _feed:  Void = feedStore.preloadAll()

                // Precargas dependientes del usuario/feeds
                async let _stats: Void = statsStore.preloadForCurrentUser(feedStore: feedStore)
                async let _ach:   Void = achievementsStore.preloadForCurrentUser()

                // Espera a que todo termine antes de mostrar la UI
                _ = await (_subsProducts, _subsRefresh, _blocks, _feed, _stats, _ach)

                appState.phase = .ready
            }
        }
    }

    private func checkSession() async {
        let session = try? await SupabaseManager.shared.client.auth.session
        self.isLoggedIn = (session != nil)
        self.isCheckingSession = false
    }
}
