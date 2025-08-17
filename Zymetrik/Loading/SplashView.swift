import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // … tu UI …
        }
        .task {
            if case .ready = appState.phase { return }
            // ⬅️ espera a la tarea asíncrona
            await SplashController.start(appState: appState)
        }
    }
}

enum SplashController {
    // ⬅️ corre en MainActor para poder mutar appState.phase
    @MainActor
    static func start(appState: AppState) async {
        appState.phase = .loading(progress: 0, message: "Preparando…")
        let initializer = AppInitializer()
        do {
            // ⬅️ el closure de progreso hace hop explícito al MainActor
            try await initializer.run { p, msg in
                await MainActor.run {
                    appState.setProgress(p, message: msg)
                }
            }
            appState.setReady()
        } catch {
            appState.setError("No se pudo iniciar la app.\n\(error.localizedDescription)")
        }
    }
}
