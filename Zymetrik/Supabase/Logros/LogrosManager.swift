import SwiftUI
import Combine

// MARK: - Manager principal para logros

class LogrosManager: ObservableObject {
    static let shared = LogrosManager()
    
    @Published var pendingAchievements: [LogroConEstado] = []
    @Published var showAchievementPopup = false
    
    private let supabaseService = SupabaseService.shared
    private var achievementCheckTimer: Timer?
    
    private init() {
        setupPeriodicCheck()
    }
    
    // MARK: - Funciones públicas para llamar desde diferentes pantallas
    
    /// Llama después de completar un entrenamiento
    func checkAchievementsAfterWorkout() {
        Task {
            await performAchievementCheck()
        }
    }
    
    /// Llama después de crear un post
    func checkAchievementsAfterPost() {
        Task {
            await performAchievementCheck()
        }
    }
    
    /// Llama después de seguir a alguien
    func checkAchievementsAfterFollow() {
        Task {
            await performAchievementCheck()
        }
    }
    
    /// Llama después de recibir un like
    func checkAchievementsAfterLike() {
        Task {
            await performAchievementCheck()
        }
    }
    
    /// Llama después de crear un set de ejercicio
    func checkAchievementsAfterSet() {
        Task {
            await performAchievementCheck()
        }
    }
    
    /// Chequeo manual (para pull-to-refresh)
    func manualAchievementCheck() async {
        await performAchievementCheck()
    }
    
    // MARK: - Funciones privadas
    
    @MainActor
    private func performAchievementCheck() async {
        let newAchievementIds = await supabaseService.awardAchievementsRPC()
        
        if !newAchievementIds.isEmpty {
            do {
                // Obtener datos completos de los nuevos logros
                let allLogros = try await supabaseService.fetchLogrosCompletos()
                let newAchievements = allLogros.filter { logro in
                    newAchievementIds.contains(logro.id) && logro.desbloqueado
                }
                
                if !newAchievements.isEmpty {
                    pendingAchievements = newAchievements
                    showAchievementPopup = true
                    
                    // Haptic feedback
                    #if os(iOS)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    #endif
                    
                    // Invalidar cache de logros para refrescar
                    supabaseService.invalidateLogrosCache()
                }
            } catch {
                print("Error obteniendo detalles de logros: \(error)")
            }
        }
    }
    
    private func setupPeriodicCheck() {
        // Chequeo periódico cada 5 minutos (opcional)
        achievementCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.performAchievementCheck()
            }
        }
    }
    
    deinit {
        achievementCheckTimer?.invalidate()
    }
}

// MARK: - Modifier para integrar logros en cualquier vista

struct LogrosModifier: ViewModifier {
    @StateObject private var logrosManager = LogrosManager.shared
    @State private var currentAchievementIndex = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                achievementPopupOverlay
            )
    }
    
    @ViewBuilder
    private var achievementPopupOverlay: some View {
        if logrosManager.showAchievementPopup && !logrosManager.pendingAchievements.isEmpty {
            LogroDesbloqueadoMejoradoView(
                logro: logrosManager.pendingAchievements[currentAchievementIndex],
                isLastAchievement: currentAchievementIndex == logrosManager.pendingAchievements.count - 1,
                achievementNumber: currentAchievementIndex + 1,
                totalAchievements: logrosManager.pendingAchievements.count
            ) {
                showNextAchievement()
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .zIndex(1000)
        }
    }
    
    private func showNextAchievement() {
        if currentAchievementIndex < logrosManager.pendingAchievements.count - 1 {
            currentAchievementIndex += 1
        } else {
            logrosManager.showAchievementPopup = false
            logrosManager.pendingAchievements = []
            currentAchievementIndex = 0
        }
    }
}

extension View {
    func withLogrosPopup() -> some View {
        modifier(LogrosModifier())
    }
}
