import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false // Solo para diseño visual

    var body: some View {
        if isLoggedIn {
            MainTabView()
        } else {
            WelcomeView()
        }
    }
}