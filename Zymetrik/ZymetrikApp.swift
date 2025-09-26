import SwiftUI

@main
struct ZymetrikApp: App {
    @StateObject private var subs = SubscriptionStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subs)
                .task {
                    await subs.loadProducts()
                    await subs.refresh()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task { await subs.refresh() }
                }
        }
    }
}
