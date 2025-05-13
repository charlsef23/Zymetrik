import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            // Configuración
        } onCompletion: { result in
            // Manejar resultado
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 45)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}