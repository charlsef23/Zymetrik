import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SocialFeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                }

            BuscarView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }

            CrearPostView()
                .tabItem {
                    Image(systemName: "plus.app")
                }

            EntrenamientoView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
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
