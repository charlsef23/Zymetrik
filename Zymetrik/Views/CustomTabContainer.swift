// CustomTabContainer.swift
import SwiftUI

struct CustomTabContainer: View {
    @State private var activeTab: TabItem = .inicio
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchFieldActive: Bool = false

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
            .padding(.bottom, 50)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
