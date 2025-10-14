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
                    SplashView()
                case .ready:
                    CustomTabContainer()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .environmentObject(appState)
        .environmentObject(contentStore)
        .environmentObject(planStore)
        .environmentObject(uiState)
        .environmentObject(routine)
        .environmentObject(subs)
        .task {
            await checkSession()
            if isLoggedIn {
                appState.phase = .loading(progress: 0, message: "Preparando…")
            }
        }
        .task {
            await subs.loadProducts()
            await subs.refresh()
        }
    }

    private func checkSession() async {
        let session = try? await SupabaseManager.shared.client.auth.session
        self.isLoggedIn = (session != nil)
        self.isCheckingSession = false
    }
}
