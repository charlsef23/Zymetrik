import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var phase: AppPhase = .loading(progress: 0, message: "Preparando…")

    func setProgress(_ value: Double, message: String? = nil) {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .loading(progress: min(max(value, 0), 1), message: message)
        }
    }

    func setReady() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            phase = .ready
        }
    }

    func setError(_ message: String) {
        withAnimation(.easeInOut) {
            phase = .error(message: message)
        }
    }
}
