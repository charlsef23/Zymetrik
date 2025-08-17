import SwiftUI
import Supabase

@MainActor
struct RootView: View {
    @StateObject private var planStore = TrainingPlanStore()   // ✅ instancia única para toda la app
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Cargando...")
            } else if isLoggedIn {
                MainTabView()
            } else {
                WelcomeView(onLogin: { self.isLoggedIn = true })
            }
        }
        .environmentObject(planStore) // ✅ disponible para EntrenamientoView y cualquier hijo
        .task {                        // ✅ estilo SwiftUI en lugar de onAppear + DispatchQueue
            await checkSession()
        }
    }

    private func checkSession() async {
        let session = try? await SupabaseManager.shared.client.auth.session
        // Ya estamos en @MainActor, podemos mutar @State directamente
        self.isLoggedIn = (session != nil)
        self.isCheckingSession = false
    }
}
