import SwiftUI
import Supabase

struct RootView: View {
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                ProgressView("Cargando...")
            } else if isLoggedIn {
                MainTabView()
            } else {
                WelcomeView(onLogin: {
                    self.isLoggedIn = true
                })
            }
        }
        .onAppear {
            Task {
                await checkSession()
            }
        }
    }

    func checkSession() async {
        let session = try? await SupabaseManager.shared.client.auth.session
        DispatchQueue.main.async {
            self.isLoggedIn = session != nil
            self.isCheckingSession = false
        }
    }
}
