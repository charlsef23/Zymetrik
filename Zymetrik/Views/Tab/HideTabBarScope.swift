import SwiftUI

struct HideTabBarScopeModifier: ViewModifier {
    @EnvironmentObject var uiState: AppUIState
    let hide: Bool

    func body(content: Content) -> some View {
        content
            .toolbar(hide ? .hidden : .visible, for: .tabBar) // iOS 16+
            .onAppear { if hide { uiState.requestHideTabBar() } }
            .onDisappear { if hide { uiState.releaseHideTabBar() } }
    }
}

public extension View {
    /// Oculta la TabBar nativa mientras esta vista exista
    func hideTabBarScope(_ hide: Bool = true) -> some View {
        modifier(HideTabBarScopeModifier(hide: hide))
    }
}
