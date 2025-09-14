import Foundation
import SwiftUI
import Supabase

@MainActor
class LogrosViewModel: ObservableObject {
    @Published var logros: [LogroConEstado] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var newlyUnlockedAchievements: [LogroConEstado] = []
    @Published var showNewAchievementPopup = false
    @Published var currentAchievementIndex = 0
    
    // Estadísticas
    @Published var totalLogros = 0
    @Published var logrosDesbloqueados = 0
    @Published var porcentajeCompletado: Double = 0
    
    // Filtros y ordenación
    @Published var showOnlyUnlocked = false
    @Published var searchText = ""
    
    private let supabaseService = SupabaseService.shared
    
    var filteredLogros: [LogroConEstado] {
        var filtered = logros
        
        // Filtro por desbloqueados
        if showOnlyUnlocked {
            filtered = filtered.filter { $0.desbloqueado }
        }
        
        // Filtro por búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter { logro in
                logro.titulo.localizedCaseInsensitiveContains(searchText) ||
                logro.descripcion.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    init() {
        Task {
            await loadLogros()
            await checkForNewAchievements()
        }
    }
    
    // MARK: - Funciones principales
    
    func loadLogros() async {
        do {
            isLoading = true
            errorMessage = nil
            
            logros = try await supabaseService.fetchLogrosCompletos()
            updateStats()
            isLoading = false
            
        } catch {
            errorMessage = "Error al cargar logros: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    func refreshLogros() async {
        await loadLogros()
        await checkForNewAchievements()
    }
    
    func checkForNewAchievements() async {
        let newAchievementIds = await supabaseService.awardAchievementsRPC()
        
        if !newAchievementIds.isEmpty {
            // Recargar logros para obtener los datos completos de los nuevos
            await loadLogros()
            
            // Encontrar los nuevos logros completos
            newlyUnlockedAchievements = logros.filter { logro in
                newAchievementIds.contains(logro.id) && logro.desbloqueado
            }
            
            if !newlyUnlockedAchievements.isEmpty {
                currentAchievementIndex = 0
                showNewAchievementPopup = true
                
                // Haptic feedback
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif
            }
        }
    }
    
    private func updateStats() {
        totalLogros = logros.count
        logrosDesbloqueados = logros.filter { $0.desbloqueado }.count
        porcentajeCompletado = totalLogros > 0 ? Double(logrosDesbloqueados) / Double(totalLogros) : 0
    }
    
    // MARK: - Gestión de popup de nuevos logros
    
    func showNextAchievement() {
        if currentAchievementIndex < newlyUnlockedAchievements.count - 1 {
            currentAchievementIndex += 1
        } else {
            showNewAchievementPopup = false
            newlyUnlockedAchievements = []
            currentAchievementIndex = 0
        }
    }
    
    func dismissNewAchievements() {
        showNewAchievementPopup = false
        newlyUnlockedAchievements = []
        currentAchievementIndex = 0
    }
    
    // MARK: - Utilidades
    
    func toggleFilter() {
        showOnlyUnlocked.toggle()
    }
    
    func clearSearch() {
        searchText = ""
    }
}

// MARK: - Extensiones para mejor UX

extension LogrosViewModel {
    var progressText: String {
        "\(logrosDesbloqueados)/\(totalLogros)"
    }
    
    var progressPercentageText: String {
        String(format: "%.0f%%", porcentajeCompletado * 100)
    }
    
    var canShowProgress: Bool {
        totalLogros > 0
    }
}
