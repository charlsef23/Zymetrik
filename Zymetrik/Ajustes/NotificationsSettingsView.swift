import SwiftUI
import UserNotifications
import OneSignalFramework // Asegúrate de tener el SDK v5

struct NotificationsSettingsView: View {
    @AppStorage("notif.pushEnabled")    private var pushEnabled: Bool = false
    @AppStorage("notif.mentionsEnabled") private var mentionsEnabled: Bool = true
    @AppStorage("notif.commentsEnabled") private var commentsEnabled: Bool = true
    @AppStorage("notif.followsEnabled")  private var followsEnabled: Bool = true
    @AppStorage("notif.soundEnabled")    private var soundEnabled: Bool = true
    @AppStorage("notif.badgesEnabled")   private var badgesEnabled: Bool = true

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var syncing = false
    @State private var syncError: String?

    var body: some View {
        Form {
            Section(header: Text("Estado de autorización")) {
                HStack {
                    Text(textForAuthorizationStatus())
                        .foregroundColor(colorForAuthorizationStatus())
                    Spacer()
                    if OneSignal.User.pushSubscription.optedIn {
                        Label("ON", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("OFF", systemImage: "xmark.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                if authorizationStatus == .denied {
                    Button("Abrir Ajustes del sistema") { openSystemSettings() }
                }
            }

            Section {
                Toggle("Notificaciones push", isOn: $pushEnabled)
                    .onChange(of: pushEnabled) { _, newVal in
                        Task { await handlePushToggle(newVal) }
                    }
            }

            Section(header: Text("Categorías")) {
                Toggle("Menciones", isOn: $mentionsEnabled)
                    .onChange(of: mentionsEnabled) { _, _ in Task { await syncWithOneSignal() } }
                Toggle("Comentarios", isOn: $commentsEnabled)
                    .onChange(of: commentsEnabled) { _, _ in Task { await syncWithOneSignal() } }
                Toggle("Seguidores", isOn: $followsEnabled)
                    .onChange(of: followsEnabled) { _, _ in Task { await syncWithOneSignal() } }
            }
            .disabled(!canUsePushControls)

            Section(header: Text("Efectos")) {
                Toggle("Sonido", isOn: $soundEnabled)
                    .onChange(of: soundEnabled) { _, _ in Task { await syncWithOneSignal() } }
                Toggle("Insignias", isOn: $badgesEnabled)
                    .onChange(of: badgesEnabled) { _, _ in Task { await syncWithOneSignal() } }
            }
            .disabled(!canUsePushControls)

            if authorizationStatus == .notDetermined || authorizationStatus == .denied {
                Section {
                    Button("Solicitar permiso de notificaciones") { requestAuthorization() }
                }
            }

            if let syncError {
                Section {
                    Text(syncError)
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }

            Section(footer: Text("Tus preferencias se guardan en este dispositivo y puedes cambiarlas cuando quieras.")) {}
        }
        .navigationTitle("Notificaciones")
        .onAppear {
            refreshAuthorizationStatus()
            pushEnabled = OneSignal.User.pushSubscription.optedIn
        }
        .task { await syncWithOneSignal() }
    }

    private var canUsePushControls: Bool {
        isAuthorized() && pushEnabled
    }

    private func isAuthorized() -> Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private func textForAuthorizationStatus() -> String {
        switch authorizationStatus {
        case .authorized:   return "Notificaciones autorizadas"
        case .denied:       return "Notificaciones denegadas"
        case .notDetermined:return "Permiso no solicitado"
        case .provisional:  return "Permiso provisional"
        case .ephemeral:    return "Permiso efímero"
        @unknown default:   return "Estado desconocido"
        }
    }

    private func colorForAuthorizationStatus() -> Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .secondary
        @unknown default: return .secondary
        }
    }

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { self.authorizationStatus = settings.authorizationStatus }
        }
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    self.refreshAuthorizationStatus()
                    if granted {
                        self.pushEnabled = true
                        Task { await self.syncWithOneSignal() }
                    }
                }
            }
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    // MARK: - OneSignal

    private func handlePushToggle(_ enable: Bool) async {
        if enable && !isAuthorized() {
            await MainActor.run { requestAuthorization() }
            return
        }
        await syncWithOneSignal()
    }

    private func syncWithOneSignal() async {
        if syncing { return }
        await MainActor.run { syncing = true; syncError = nil }

        func b(_ v: Bool) -> String { v ? "true" : "false" }

        OneSignal.User.addTag(key: "notif_push",    value: b(pushEnabled && isAuthorized()))
        OneSignal.User.addTag(key: "notif_mentions",value: b(mentionsEnabled))
        OneSignal.User.addTag(key: "notif_comments",value: b(commentsEnabled))
        OneSignal.User.addTag(key: "notif_follows", value: b(followsEnabled))
        OneSignal.User.addTag(key: "notif_sound",   value: b(soundEnabled))
        OneSignal.User.addTag(key: "notif_badges",  value: b(badgesEnabled))

        await MainActor.run { syncing = false }
    }
}

