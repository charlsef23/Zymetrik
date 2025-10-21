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

// MARK: - Persistencia simple para saber a quién hay logueado en OneSignal
private enum OneSignalSession {
    private static let key = "onesignal.externalId"

    static var currentExternalId: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let v = newValue { UserDefaults.standard.set(v, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
    }
}

// MARK: - AppDelegate
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, @MainActor UNUserNotificationCenterDelegate {

    private let clickHandler = OSClickHandler()
    private var loginObserver: NSObjectProtocol?

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // ✅ Inicializa OneSignal una vez al arranque
        OneSignal.initialize("6da7a54a-67c9-45dd-a816-680c69d2e690", withLaunchOptions: launchOptions)

        // 🔔 Delegate de notificaciones
        UNUserNotificationCenter.current().delegate = self

        // 🎯 Listener de clics
        OneSignal.Notifications.addClickListener(clickHandler)

        // 🧭 Tras login correcto (tu app emite esta notificación cuando termina el sign-in de Supabase)
        loginObserver = NotificationCenter.default.addObserver(
            forName: .didLoginSuccess,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.identifyOneSignalIfNeeded()
            }
        }

        // Si ya había sesión (app relanzada), intenta identificar de forma idempotente
        Task { @MainActor in
            await identifyOneSignalIfNeeded()
        }

        // (Opcional) Log de estado
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.debugPrintOneSignalState(context: "arranque")
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Idempotente: no re-login si no cambió el usuario
        Task { @MainActor in
            await identifyOneSignalIfNeeded()
            debugPrintOneSignalState(context: "willEnterForeground")
        }
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

    // MARK: - APNs callbacks (dispositivo real)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📬 APNs deviceToken:", tokenString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs register error:", error.localizedDescription)
    }

    // MARK: - Pedir permiso (llámalo cuando te interese, por ejemplo tras onboarding)
    func requestPushPermissionIfNeeded() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("🔔 Permiso push:", accepted)
            // Registrar APNs (en iPhone real)
            UIApplication.shared.registerForRemoteNotifications()
        }, fallbackToSettings: true)
    }

    // MARK: - Identificar OneSignal de forma idempotente
    private func identifyOneSignalIfNeeded() async {
        // 1) Obtener UID actual de Supabase (si no hay, desloguear si procede)
        let rawUID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString
        guard let uidRaw = rawUID else {
            // No sesión → cerrar sesión OneSignal si había otra
            if OneSignalSession.currentExternalId != nil {
                OneSignal.logout()
                OneSignalSession.currentExternalId = nil
                print("ℹ️ Sin sesión Supabase → OneSignal.logout()")
            }
            return
        }

        let externalId = uidRaw.lowercased()

        // 2) Evitar re-login si ya estamos con el mismo externalId
        if OneSignalSession.currentExternalId == externalId {
            // Ya identificado, nada que hacer
            return
        }

        // 3) Si hay otro usuario distinto, logout primero
        if let current = OneSignalSession.currentExternalId, current != externalId {
            OneSignal.logout()
            OneSignalSession.currentExternalId = nil
        }

        // 4) Hacer login (no hace falta esperar al token APNs)
        OneSignal.login(externalId)
        OneSignalSession.currentExternalId = externalId
        print("✅ OneSignal vinculado a (lowercased): \(externalId)")

        // (Opcional) estado tras login
        debugPrintOneSignalState(context: "tras OneSignal.login")
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
