import SwiftUI

struct CustomTabContainer: View {
    @EnvironmentObject private var uiState: AppUIState

    @State private var activeTab: TabItem = .inicio
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchFieldActive: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    // Mantén instancias vivas de cada pestaña
    @State private var inicioView = InicioView()
    @State private var entrenamientoView = EntrenamientoView()
    @State private var perfilView = PerfilView()

    var body: some View {
        ZStack(alignment: .bottom) {

            // ==== CONTENIDO DE TABS: siempre montado ====
            ZStack {
                // Inicio
                inicioView
                    .opacity(activeTab == .inicio && !isSearchOverlayActive ? 1 : 0)
                    .allowsHitTesting(activeTab == .inicio && !isSearchOverlayActive)
                    .zIndex(activeTab == .inicio ? 1 : 0)

                // Entrenamiento
                entrenamientoView
                    .opacity(activeTab == .entrenamiento && !isSearchOverlayActive ? 1 : 0)
                    .allowsHitTesting(activeTab == .entrenamiento && !isSearchOverlayActive)
                    .zIndex(activeTab == .entrenamiento ? 1 : 0)

                // Perfil
                perfilView
                    .opacity(activeTab == .perfil && !isSearchOverlayActive ? 1 : 0)
                    .allowsHitTesting(activeTab == .perfil && !isSearchOverlayActive)
                    .zIndex(activeTab == .perfil ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ==== BUSCADOR COMO OVERLAY ====
            if isSearchOverlayActive {
                BuscarView(
                    searchText: $searchText,
                    isSearchActive: $isSearchFieldActive
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(5)
            }

            // ==== TAB BAR ====
            CustomTabBar(
                showsSearchBar: true,
                activeTab: $activeTab,
                searchText: $searchText,
                onSearchBarExpanded: { isSearchExpanded = $0 },
                onSearchTextFieldActive: { isSearchFieldActive = $0 }
            )
            .padding(.bottom, uiState.hideTabBar ? 0 : max(50, keyboardHeight + 10))
            .opacity(uiState.hideTabBar ? 0 : 1)
            .frame(height: uiState.hideTabBar ? 0 : nil)
            .allowsHitTesting(!uiState.hideTabBar)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(10)
        }
        .ignoresSafeArea(edges: .bottom)
        // Teclado
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            let overlap = max(0, UIScreen.main.bounds.height - endFrame.origin.y)
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = overlap }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        // Si ocultas la barra, cierra búsqueda
        .onChange(of: uiState.hideTabBar) { _, hidden in
            if hidden {
                isSearchExpanded = false
                isSearchFieldActive = false
            }
        }
    }

    private var isSearchOverlayActive: Bool {
        isSearchExpanded || isSearchFieldActive || !searchText.isEmpty
    }
}
