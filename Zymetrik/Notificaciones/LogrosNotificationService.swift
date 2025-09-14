import Foundation
import UserNotifications
import SwiftUI

// MARK: - Servicio de notificaciones para logros

class LogrosNotificationService: ObservableObject {
    static let shared = LogrosNotificationService()
    
    @Published var notificationsEnabled = false
    
    private init() {
        checkNotificationPermissions()
    }
    
    // MARK: - Configuración de permisos
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                notificationsEnabled = granted
            }
            
            return granted
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notificaciones de logros
    
    /// Programa una notificación local para un logro desbloqueado
    func scheduleAchievementNotification(for logro: LogroConEstado, delay: TimeInterval = 0) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Logro desbloqueado! 🏆"
        content.body = "\(logro.titulo) - \(logro.descripcion)"
        content.sound = .default
        content.badge = 1
        
        // Datos adicionales
        content.userInfo = [
            "type": "achievement",
            "achievement_id": logro.id.uuidString,
            "achievement_title": logro.titulo
        ]
        
        // Programar notificación
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(logro.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling achievement notification: \(error)")
            } else {
                print("✅ Scheduled notification for achievement: \(logro.titulo)")
            }
        }
    }
    
    /// Programa notificaciones para múltiples logros
    func scheduleMultipleAchievementNotifications(for logros: [LogroConEstado]) {
        guard !logros.isEmpty else { return }
        
        if logros.count == 1 {
            scheduleAchievementNotification(for: logros[0])
        } else {
            // Para múltiples logros, enviar una notificación resumen
            let content = UNMutableNotificationContent()
            content.title = "¡\(logros.count) logros desbloqueados! 🎉"
            content.body = "Has desbloqueado: \(logros.map { $0.titulo }.joined(separator: ", "))"
            content.sound = .default
            content.badge = NSNumber(value: logros.count)
            
            content.userInfo = [
                "type": "multiple_achievements",
                "achievement_count": logros.count,
                "achievement_ids": logros.map { $0.id.uuidString }
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "multiple_achievements_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling multiple achievement notification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Notificaciones de recordatorio
    
    /// Programa recordatorio para entrenar
    func scheduleWorkoutReminder(at date: Date, message: String = "¡Hora de entrenar! 💪") {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de entrenamiento"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "workout_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Programa recordatorio de racha de entrenamientos
    func scheduleStreakReminder() {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Mantén tu racha! 🔥"
        content.body = "No olvides entrenar hoy para mantener tu racha activa"
        content.sound = .default
        
        // Programar para mañana si no ha entrenado hoy
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 horas
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Gestión de notificaciones
    
    /// Cancela todas las notificaciones de logros pendientes
    func cancelAllAchievementNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let achievementIds = requests
                .filter { $0.identifier.starts(with: "achievement_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: achievementIds)
        }
    }
    
    /// Cancela notificación específica de logro
    func cancelAchievementNotification(for logroId: UUID) {
        let identifier = "achievement_\(logroId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Limpia el badge de la app
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Manejo de respuestas a notificaciones
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "achievement":
            if let achievementId = userInfo["achievement_id"] as? String,
               let uuid = UUID(uuidString: achievementId) {
                // Navegar a la pantalla de logros o mostrar detalles
                NotificationCenter.default.post(
                    name: .showAchievementDetails,
                    object: uuid
                )
            }
            
        case "multiple_achievements":
            // Navegar a la pantalla de logros
            NotificationCenter.default.post(
                name: .showAchievementsScreen,
                object: nil
            )
            
        default:
            break
        }
        
        // Limpiar badge después de interactuar
        clearBadge()
    }
}

// MARK: - Extensiones para configurar categorías de notificación

extension LogrosNotificationService {
    
    func setupNotificationCategories() {
        let workoutReminderAction = UNNotificationAction(
            identifier: "WORKOUT_NOW",
            title: "Entrenar ahora",
            options: [.foreground]
        )
        
        let workoutLaterAction = UNNotificationAction(
            identifier: "WORKOUT_LATER",
            title: "Más tarde",
            options: []
        )
        
        let workoutReminderCategory = UNNotificationCategory(
            identifier: "WORKOUT_REMINDER",
            actions: [workoutReminderAction, workoutLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        let achievementAction = UNNotificationAction(
            identifier: "VIEW_ACHIEVEMENT",
            title: "Ver logro",
            options: [.foreground]
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [achievementAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            workoutReminderCategory,
            achievementCategory
        ])
    }
}

// MARK: - Notificaciones personalizadas

extension LogrosNotificationService {
    
    /// Crea mensajes personalizados basados en el tipo de logro
    private func customMessage(for logro: LogroConEstado) -> String {
        switch logro.titulo.lowercased() {
        case let title where title.contains("primer"):
            return "¡Genial! \(logro.titulo). Este es solo el comienzo de tu viaje fitness 🚀"
            
        case let title where title.contains("maestro"):
            return "¡Increíble! \(logro.titulo). Eres un verdadero atleta dedicado 👑"
            
        case let title where title.contains("constante"):
            return "¡Excelente! \(logro.titulo). La consistencia es la clave del éxito 🔥"
            
        case let title where title.contains("popular"):
            return "¡Wow! \(logro.titulo). La comunidad ama tu contenido ❤️"
            
        case let title where title.contains("sociable"):
            return "¡Fantástico! \(logro.titulo). Construyendo una gran red fitness 🤝"
            
        default:
            return "\(logro.titulo) - \(logro.descripcion)"
        }
    }
}

// MARK: - Notificaciones de Notification Center

extension Notification.Name {
    static let showAchievementDetails = Notification.Name("showAchievementDetails")
    static let showAchievementsScreen = Notification.Name("showAchievementsScreen")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Integración con LogrosManager

extension LogrosManager {
    
    /// Integra notificaciones en el sistema de logros
    func enableNotifications() {
        Task {
            let granted = await LogrosNotificationService.shared.requestNotificationPermissions()
            if granted {
                LogrosNotificationService.shared.setupNotificationCategories()
                print("✅ Notifications enabled for achievements")
            }
        }
    }
    
    /// Notifica cuando se desbloquean logros
    private func notifyAchievementUnlocked(_ achievements: [LogroConEstado]) {
        // Solo enviar notificación si la app está en background
        guard UIApplication.shared.applicationState != .active else { return }
        
        LogrosNotificationService.shared.scheduleMultipleAchievementNotifications(for: achievements)
    }
}
