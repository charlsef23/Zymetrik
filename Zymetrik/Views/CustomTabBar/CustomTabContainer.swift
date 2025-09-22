import SwiftUI

struct CustomTabContainer: View {
    @EnvironmentObject private var uiState: AppUIState

    @State private var activeTab: TabItem = .inicio
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchFieldActive: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido según la pestaña activa o búsqueda
            Group {
                if isSearchExpanded || isSearchFieldActive || !searchText.isEmpty {
                    BuscarView(
                        searchText: $searchText,
                        isSearchActive: $isSearchFieldActive
                    )
                } else {
                    switch activeTab {
                    case .inicio:
                        InicioView()
                    case .entrenamiento:
                        EntrenamientoView()
                    case .perfil:
                        PerfilView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Barra de pestañas — se muestra salvo que uiState.hideTabBar sea true
            CustomTabBar(
                showsSearchBar: true,
                activeTab: $activeTab,
                searchText: $searchText,
                onSearchBarExpanded: { isSearchExpanded = $0 },
                onSearchTextFieldActive: { isSearchFieldActive = $0 }
            )
            // 👇 Nada de huecos cuando está oculta
            .padding(.bottom, uiState.hideTabBar ? 0 : max(50, keyboardHeight + 10))
            .opacity(uiState.hideTabBar ? 0 : 1)
            .frame(height: uiState.hideTabBar ? 0 : nil)
            .allowsHitTesting(!uiState.hideTabBar)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(10)
        }
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            let overlap = max(0, UIScreen.main.bounds.height - endFrame.origin.y)
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = overlap }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        // Si se oculta la barra, cierra el estado de búsqueda para evitar “zombis”
        .onChange(of: uiState.hideTabBar) { _, hidden in
            if hidden {
                isSearchExpanded = false
                isSearchFieldActive = false
            }
        }
    }
}
