import SwiftUI
import AuthenticationServices
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var usuarios: [User]

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)

                    Text("FitFlow")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Text("Tu compañero ideal para el entrenamiento")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    NavigationLink(destination: LoginView()) {
                        Text("Iniciar sesión")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    NavigationLink(destination: RegistroView()) {
                        Text("Registrarse")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    let name = credential.fullName?.givenName ?? "Usuario"
                                    let email = credential.email ?? "usuario@icloud.com"

                                    if !usuarios.contains(where: { $0.email == email }) {
                                        let nuevoUsuario = User(name: name, email: email, password: "apple-auth")
                                        context.insert(nuevoUsuario)
                                        try? context.save()
                                    }

                                    userName = name
                                    userEmail = email
                                }
                            case .failure(let error):
                                print("Error al iniciar sesión con Apple: \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 45)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}
