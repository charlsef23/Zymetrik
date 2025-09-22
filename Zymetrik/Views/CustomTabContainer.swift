// CustomTabContainer.swift
import SwiftUI

struct CustomTabContainer: View {
    @State private var activeTab: TabItem = .inicio
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchFieldActive: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido según la pestaña activa o la búsqueda
            Group {
                if isSearchExpanded || isSearchFieldActive || !searchText.isEmpty {
                    // BuscarView debe recibir los bindings reales
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // Barra de pestañas personalizada
            CustomTabBar(
                showsSearchBar: true,
                activeTab: $activeTab,
                searchText: $searchText,
                onSearchBarExpanded: { expanded in
                    isSearchExpanded = expanded
                },
                onSearchTextFieldActive: { active in
                    isSearchFieldActive = active
                }
            )
            .padding(.bottom, max(50, keyboardHeight + 10))
        }
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard
                let userInfo = notification.userInfo,
                let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { return }
            let screenHeight = UIScreen.main.bounds.height
            let keyboardTopY = endFrame.origin.y
            let overlap = max(0, screenHeight - keyboardTopY)
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = overlap
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
}
