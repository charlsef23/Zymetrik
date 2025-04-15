import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "inicio"
    @State private var fechaSeleccionada: Date = Date()

    var body: some View {
        TabView(selection: $selectedTab) {
            MainMenuView(selectedTab: $selectedTab, fechaSeleccionada: $fechaSeleccionada)
                .tabItem {
                    Label("Inicio", systemImage: "house")
                }
                .tag("inicio")

            CalendarioView(fechaSeleccionada: $fechaSeleccionada)
                .tabItem {
                    Label("Calendario", systemImage: "calendar")
                }
                .tag("calendario")
                .onAppear {
                    if selectedTab == "calendario" {
                        fechaSeleccionada = Date()
                    }
                }

            RutinasView()
                .tabItem {
                    Label("Rutinas", systemImage: "list.bullet.rectangle")
                }
                .tag("rutinas")

            PerfilView()
                .tabItem {
                    Label("Perfil", systemImage: "person")
                }
                .tag("perfil")
        }
    }
}
