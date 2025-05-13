import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            Spacer()

            Image("LogoSinFondoNegro")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .padding(.bottom, 8)

            Text("Bienvenido a Zymetrik")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Spacer()

            VStack(spacing: 14) {
                Button(action: {
                    // Acción login
                }) {
                    Text("Iniciar sesión")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }

                HStack(spacing: 4) {
                    Text("¿No tienes cuenta?")
                        .foregroundColor(.secondary)
                        .font(.footnote)

                    Button(action: {
                        // Acción registro
                    }) {
                        Text("Regístrate")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }

                SignInWithAppleButtonView()
                    .frame(height: 45)
                    .cornerRadius(12)
                    .padding(.top, 8)
            }
            .padding(.horizontal)

            Text("Privacidad. Progreso. Comunidad.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeView()
}