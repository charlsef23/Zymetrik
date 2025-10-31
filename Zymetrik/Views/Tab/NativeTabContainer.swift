import SwiftUI

struct NativeTabContainer: View {
    @EnvironmentObject private var uiState: AppUIState
    @State private var activeTab: TabItem = .inicio

    // Instancias vivas de cada pestaña
    @State private var inicioView = InicioView()
    @State private var entrenamientoView = EntrenamientoView()
    @State private var searchView = SearchTabView()
    @State private var perfilView = PerfilView()

    var body: some View {
        TabView(selection: $activeTab) {
            inicioView
                .tabItem { Label(TabItem.inicio.title, systemImage: TabItem.inicio.symbol) }
                .tag(TabItem.inicio)

            entrenamientoView
                .tabItem { Label(TabItem.entrenamiento.title, systemImage: TabItem.entrenamiento.symbol) }
                .tag(TabItem.entrenamiento)

            searchView
                .tabItem { Label(TabItem.search.title, systemImage: TabItem.search.symbol) }
                .tag(TabItem.search)

            perfilView
                .tabItem { Label(TabItem.perfil.title, systemImage: TabItem.perfil.symbol) }
                .tag(TabItem.perfil)
        }
        .toolbar(uiState.hideTabBar ? .hidden : .visible, for: .tabBar)
    }
}
