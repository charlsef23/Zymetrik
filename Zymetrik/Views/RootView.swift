import SwiftUI
import Supabase

@MainActor
struct RootView: View {
    // Estado de sesión
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    // Splash / prefetch
    @StateObject private var appState = AppState()
    @StateObject private var contentStore = ContentStore.shared

    // Store global para planes
    @StateObject private var planStore = TrainingPlanStore()

    // Estado UI global (TabBar, etc.)
    @StateObject private var uiState = AppUIState()

    // ⬇️ NUEVO: store de suscripción (sustituye por el tuyo si ya lo tienes)
    @StateObject private var suscripcion = SuscripcionStore()

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Cargando…")
            } else if !isLoggedIn {
                // No autenticado → onboarding/login
                WelcomeView(onLogin: {
                    self.isLoggedIn = true
                    appState.phase = .loading(progress: 0, message: "Preparando…")
                })
            } else {
                // Autenticado → Splash + contenido
                switch appState.phase {
                case .loading, .error:
                    SplashView() // corre SplashController.start automáticamente en .task
                case .ready:
                    CustomTabContainer()
                        .transition(
                            AnyTransition.opacity
                                .combined(with: AnyTransition.scale(scale: 0.98))
                        )
                }
            }
        }
        // Env objects disponibles para toda la app
        .environmentObject(appState)
        .environmentObject(contentStore)
        .environmentObject(planStore)
        .environmentObject(uiState)
        .environmentObject(suscripcion) // ⬅️ importante para EntrenamientoPersonalizadoView
        .task {
            await checkSession()
            if isLoggedIn {
                appState.phase = .loading(progress: 0, message: "Preparando…")
            }
        }
    }

    private func checkSession() async {
        let session = try? await SupabaseManager.shared.client.auth.session
        self.isLoggedIn = (session != nil)
        self.isCheckingSession = false
    }
}
