import SwiftUI
import SwiftData
import AuthenticationServices

struct LoginView: View {
    @Environment(\.modelContext) private var context
    @Query private var usuarios: [User]

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var mostrarError = false

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Iniciar sesión")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)

                SecureField("Contraseña", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Entrar") {
                    iniciarSesion()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                if mostrarError {
                    Text("Correo o contraseña incorrectos.")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Divider().padding(.vertical, 10)

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

                                // Verifica si el usuario ya existe
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

                Spacer()
            }
            .padding()
        }
    }

    func iniciarSesion() {
        if let usuario = usuarios.first(where: { $0.email == email && $0.password == password }) {
            userName = usuario.name
            userEmail = usuario.email
            mostrarError = false
        } else {
            mostrarError = true
        }
    }
}
