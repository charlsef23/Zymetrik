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

    // Tu store global para planes
    @StateObject private var planStore = TrainingPlanStore()

    // ⬇️ Nuevo: estado UI global (controla ocultar/mostrar la TabBar)
    @StateObject private var uiState = AppUIState()

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Cargando…")
            } else if !isLoggedIn {
                // No autenticado → onboarding/login
                WelcomeView(onLogin: {
                    // Tras login, pasamos a logged-in y dejamos que Splash arranque
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
        // ⬇️ Importante: inyectar el estado UI global aquí
        .environmentObject(uiState)
        .task {
            await checkSession()
            // Si ya hay sesión al abrir la app, dispara el splash inmediatamente
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
