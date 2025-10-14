import UIKit
import UserNotifications
import OneSignalFramework
import Supabase

// MARK: - Notificaciones internas
extension Notification.Name {
    static let didTapRemoteNotification = Notification.Name("didTapRemoteNotification")
    static let didLoginSuccess = Notification.Name("didLoginSuccess")
}

// MARK: - Click handler OneSignal (v5)
final class OSClickHandler: NSObject, OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        let data = event.notification.additionalData ?? [:]
        print("📩 Notificación clicada. data:", data)
        NotificationCenter.default.post(name: .didTapRemoteNotification, object: nil, userInfo: data)
    }
}

// MARK: - AppDelegate (todo en MainActor para evitar data races en Swift 6)
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, @MainActor UNUserNotificationCenterDelegate {

    private let clickHandler = OSClickHandler()
    private var loginObserver: NSObjectProtocol?

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // ✅ Inicializa OneSignal
        OneSignal.initialize("6da7a54a-67c9-45dd-a816-680c69d2e690", withLaunchOptions: launchOptions)

        // 🔔 Delegate de notificaciones (no pedimos permiso aún)
        UNUserNotificationCenter.current().delegate = self

        // 🎯 Listener de clics
        OneSignal.Notifications.addClickListener(clickHandler)

        // 🧭 Pedir permiso + vincular SOLO tras login correcto
        loginObserver = NotificationCenter.default.addObserver(
            forName: .didLoginSuccess,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.requestPushPermissionAndLink()
            }
        }

        // Si ya había sesión (app relanzada), enlaza
        Task { @MainActor in
            self.linkOneSignalToCurrentUser()
        }

        // Debug post-arranque
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.debugPrintOneSignalState(context: "arranque")
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        linkOneSignalToCurrentUser()
        debugPrintOneSignalState(context: "willEnterForeground")
    }

    deinit {
        if let loginObserver { NotificationCenter.default.removeObserver(loginObserver) }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    // MARK: - APNs callbacks (útiles en dispositivo real)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📬 APNs deviceToken:", tokenString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs register error:", error.localizedDescription)
    }

    // MARK: - Pide permiso + registra APNs + login OneSignal (con UID en minúsculas)
    private func requestPushPermissionAndLink() {
        OneSignal.Notifications.requestPermission({ [weak self] accepted in
            guard let self else { return }
            print("🔔 Permiso push:", accepted)

            // Registrar APNs (iPhone real)
            UIApplication.shared.registerForRemoteNotifications()

            // Vincular tras pedir permiso
            self.linkOneSignalToCurrentUser()

            // Revisar estado después
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.debugPrintOneSignalState(context: "tras requestPermission")
            }
        }, fallbackToSettings: true)
    }

    // MARK: - Vincular dispositivo ↔ usuario Supabase
    private func linkOneSignalToCurrentUser() {
        Task { @MainActor in
            guard let rawUID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else {
                OneSignal.logout()
                print("ℹ️ Sin sesión Supabase → OneSignal.logout()")
                return
            }
            let uid = rawUID.lowercased()

            // Limpieza por si había otro external_id
            OneSignal.logout()
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Espera a tener subscription id + APNs token
            for _ in 0..<40 {
                if OneSignal.User.pushSubscription.id != nil,
                   OneSignal.User.pushSubscription.token != nil { break }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            OneSignal.login(uid)
            print("✅ OneSignal vinculado a (lowercased):", uid)
            debugPrintOneSignalState(context: "tras OneSignal.login(lowercased)")
        }
    }

    // MARK: - Debug OneSignal
    private func debugPrintOneSignalState(context: String) {
        let sub = OneSignal.User.pushSubscription
        print("🔎 [OneSignal] \(context)")
        print("   optedIn:", sub.optedIn)
        print("   subscription_id:", sub.id ?? "nil")
        print("   token:", sub.token ?? "nil")
    }
}

