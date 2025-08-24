import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {

            InicioView()
                .tabItem {
                    Image(systemName: "house")
                }
            
            BuscarView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
            EntrenamientoView()
                .tabItem {
                    Image(systemName: "dumbbell")
                }

            PerfilView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
        }
        .accentColor(.mainTab)
    }
}

#Preview {
    MainTabView()
}
