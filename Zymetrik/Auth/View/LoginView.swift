import SwiftUI
import Supabase

struct LoginView: View {
    var onSuccess: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var aceptaTerminos = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image("LogoSinFondoNegro")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .padding(.bottom, 8)

                VStack(spacing: 8) {
                    Text("Iniciar sesión").font(.title).fontWeight(.semibold)
                    Text("Accede a tu cuenta de Zymetrik")
                        .font(.subheadline).foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    CustomTextField(placeholder: "Correo electrónico", text: $email, icon: "envelope")
                        .frame(height: 45)
                    CustomSecureField(placeholder: "Contraseña", text: $password)
                        .frame(height: 45)
                    HStack {
                        Spacer()
                        Button("¿Olvidaste tu contraseña?") {}
                            .font(.footnote).foregroundColor(.secondary)
                    }
                }
                HStack(alignment: .top, spacing: 8) {
                    Button(action: { aceptaTerminos.toggle() }) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: aceptaTerminos ? "checkmark.square.fill" : "square")
                                .foregroundColor(aceptaTerminos ? .accentColor : .secondary)
                            Text("Acepto los ")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Aceptar términos y condiciones")
                    .accessibilityAddTraits(aceptaTerminos ? [.isSelected] : [])

                    NavigationLink(destination: TermsAndConditionsView(isModal: false)) {
                        Text("Términos y Condiciones").underline()
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red).font(.footnote)
                }

                Button {
                    guard aceptaTerminos else {
                        errorMessage = "Debes aceptar los Términos y Condiciones."
                        return
                    }
                    Task { await iniciarSesion() }
                } label: {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 45)
                    } else {
                        Text("Entrar")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity).frame(height: 45)
                            .background(Color.white).foregroundColor(.black).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1))
                            .opacity(aceptaTerminos ? 1 : 0.5)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Inicio de sesión
    func iniciarSesion() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
            print("✅ Sesión iniciada correctamente")

            // Navega y dispara el evento para que AppDelegate pida permiso + OneSignal.login
            DispatchQueue.main.async {
                onSuccess?()
                NotificationCenter.default.post(name: .didLoginSuccess, object: nil)
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            print("❌ Error al iniciar sesión:", error)
        }
    }
}
