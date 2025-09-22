import SwiftUI

struct HideTabBarScope: ViewModifier {
    @EnvironmentObject var uiState: AppUIState

    func body(content: Content) -> some View {
        content
            .onAppear { uiState.requestHideTabBar() }
            .onDisappear { uiState.releaseHideTabBar() }
    }
}

public extension View {
    /// Oculta la CustomTabBar mientras esta vista exista (balanceado con contador)
    func hideTabBarScope() -> some View {
        self.modifier(HideTabBarScope())
    }
}
