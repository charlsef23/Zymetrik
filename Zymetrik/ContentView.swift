import SwiftUI

struct ContentView: View {
    @AppStorage("userName") var userName: String = ""

    var body: some View {
        if userName.isEmpty {
            WelcomeView()
        } else {
            MainTabView()
        }
    }
}
