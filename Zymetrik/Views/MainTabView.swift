import SwiftUI

private enum MainTab: Int, CaseIterable {
    case inicio, buscar, entrenamiento, perfil

    var systemImage: String {
        switch self {
        case .inicio: return "house"
        case .buscar: return "magnifyingglass"
        case .entrenamiento: return "dumbbell"
        case .perfil: return "person.crop.circle"
        }
    }
}

struct MainTabView: View {
    @State private var selection: MainTab = .inicio

    var body: some View {
        TabView(selection: $selection) {
            InicioView()
                .tabItem {
                    Image(systemName: MainTab.inicio.systemImage)
                    Text("Inicio")
                }
                .tag(MainTab.inicio)

            BuscarView()
                .tabItem {
                    Image(systemName: MainTab.buscar.systemImage)
                    Text("Buscar")
                }
                .tag(MainTab.buscar)

            EntrenamientoView()
                .tabItem {
                    Image(systemName: MainTab.entrenamiento.systemImage)
                    Text("Entrenamiento")
                }
                .tag(MainTab.entrenamiento)

            PerfilView()
                .tabItem {
                    Image(systemName: MainTab.perfil.systemImage)
                    Text("Perfil")
                }
                .tag(MainTab.perfil)
        }
        .tint(Color.mainTab)
    }
}

#Preview {
    MainTabView()
}
