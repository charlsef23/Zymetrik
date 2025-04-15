import SwiftUI
import AuthenticationServices
import SwiftData

struct RegistroView: View {
    @Environment(\.modelContext) private var context
    @Query private var usuarios: [User]

    @State private var nombre = ""
    @State private var email = ""
    @State private var password = ""
    
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Crear cuenta")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            TextField("Nombre", text: $nombre)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)

            SecureField("Contraseña", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                // Guardar localmente y con SwiftData (opcional)
                let nuevoUsuario = User(name: nombre, email: email, password: password)
                context.insert(nuevoUsuario)
                try? context.save()
                userName = nombre
                userEmail = email
            }) {
                Text("Registrarse")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            // CONTINUAR CON APPLE
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

                            // Guardar en SwiftData
                            let nuevoUsuario = User(name: name, email: email, password: "apple-auth")
                            context.insert(nuevoUsuario)
                            try? context.save()

                            // Guardar en AppStorage también
                            userName = name
                            userEmail = email
                        }
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .navigationTitle("Registro")
    }
}
