import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowImage = nil
        appearance.shadowColor = nil

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {
        TabView {
            SocialFeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                        .padding(.top, 4)
                }

            EntrenamientoView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                        .padding(.top, 4)
                }

            PerfilView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                        .padding(.top, 4)
                }
        }
        .accentColor(.black)
    }
}

#Preview {
    MainTabView()
}
