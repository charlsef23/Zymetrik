import SwiftUI

struct RegistroView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("LogoSinFondoNegro")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("Crear cuenta")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Únete a la comunidad Zymetrik")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                CustomTextField(placeholder: "Nombre de usuario", text: $username, icon: "person")
                    .frame(height: 45)

                CustomTextField(placeholder: "Correo electrónico", text: $email, icon: "envelope")
                    .frame(height: 45)

                CustomSecureField(placeholder: "Contraseña", text: $password)
                    .frame(height: 45)
            }

            VStack(spacing: 14) {
                Button(action: {
                    // Acción registrarse
                }) {
                    Text("Registrarme")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }

                SignInWithAppleButtonView()
                    .frame(height: 45)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    RegistroView()
}