import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {

            BuscarView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
            EntrenamientoView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }

            PerfilView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
        }
        .accentColor(.black)
    }
}

#Preview {
    MainTabView()
}
