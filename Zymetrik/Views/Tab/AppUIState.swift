import SwiftUI

final class AppUIState: ObservableObject {
    // Estado publicado que lee el contenedor para mostrar/ocultar la barra
    @Published private(set) var hideTabBar: Bool = false

    // Contador de peticiones activas de ocultación
    private var hideRequests: Int = 0

    /// Llama cuando una vista quiere ocultar la barra (en .onAppear del modifier)
    func requestHideTabBar() {
        hideRequests += 1
        if hideRequests < 0 { hideRequests = 0 }
        update()
    }

    /// Llama cuando una vista deja de necesitar ocultar la barra (en .onDisappear del modifier)
    func releaseHideTabBar() {
        hideRequests = max(0, hideRequests - 1)
        update()
    }

    /// Fuerza reset por si alguna vista no liberó (opcional)
    func resetHideTabBar() {
        hideRequests = 0
        update()
    }

    private func update() {
        hideTabBar = hideRequests > 0
    }
}
