import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    var onLogin: (() -> Void)? = nil  // 🔁 callback desde RootView

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image(colorScheme == .dark ? "LogoSinFondo" : "LogoSinFondoNegro")
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
                    // Botón para ir a LoginView con onLogin
                    NavigationLink(destination: LoginView(onSuccess: {
                        onLogin?()
                    })) {
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

                        // Botón para ir a RegistroView con onLogin
                        NavigationLink(destination: RegistroView(onSuccess: {
                            onLogin?()
                        })) {
                            Text("Regístrate")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                    }
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
}

#Preview {
    WelcomeView()
}
