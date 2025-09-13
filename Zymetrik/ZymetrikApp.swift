import SwiftUI

@main
struct ZymetrikApp: App {
    // Estado global que ya usas
    @StateObject private var appState = AppState()
    // 🟢 Store de planes/rutinas sincronizado con Supabase
    @StateObject private var planStore = TrainingPlanStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(planStore) 
        }
    }
}
