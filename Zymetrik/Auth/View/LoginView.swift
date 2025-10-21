import SwiftUI
import Supabase

struct LoginView: View {
    var onSuccess: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var aceptaTerminos = false

    // Reset password UI
    @State private var showResetSheet = false
    @State private var resetEmail = ""
    @State private var resetInFlight = false
    @State private var resetInfoMessage: String?

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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    CustomSecureField(placeholder: "Contraseña", text: $password)
                        .frame(height: 45)

                    HStack {
                        Spacer()
                        Button("¿Olvidaste tu contraseña?") {
                            resetEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            resetInfoMessage = nil
                            showResetSheet = true
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    Button(action: { aceptaTerminos.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: aceptaTerminos ? "checkmark.square.fill" : "square")
                                .foregroundColor(aceptaTerminos ? .accentColor : .secondary)
                            Text("Acepto los ").foregroundColor(.secondary)
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
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button {
                    guard aceptaTerminos else {
                        errorMessage = "Debes aceptar los Términos y Condiciones."
                        return
                    }
                    Task { await iniciarSesion() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 45)
                    } else {
                        Text("Entrar")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1))
                            .opacity(aceptaTerminos ? 1 : 0.5)
                    }
                }
                .disabled(!aceptaTerminos)

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
        }
        // Sheet “Olvidé mi contraseña”
        .sheet(isPresented: $showResetSheet) {
            NavigationStack {
                Form {
                    Section("Correo para recuperar") {
                        TextField("tu@correo.com", text: $resetEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.send)
                            .onSubmit { Task { await enviarCorreoRecuperacion() } }
                    }
                    if let msg = resetInfoMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Button {
                        Task { await enviarCorreoRecuperacion() }
                    } label: {
                        if resetInFlight {
                            ProgressView()
                        } else {
                            Text("Enviar enlace de recuperación")
                        }
                    }
                    .disabled(resetInFlight || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .navigationTitle("Recuperar contraseña")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { showResetSheet = false }
                    }
                }
            }
        }
    }

    // MARK: - Inicio de sesión
    func iniciarSesion() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mail.isEmpty, !password.isEmpty else {
            errorMessage = "Introduce email y contraseña."
            return
        }

        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(email: mail, password: password)
            print("✅ Sesión iniciada correctamente")
            DispatchQueue.main.async {
                onSuccess?()
                NotificationCenter.default.post(name: .didLoginSuccess, object: nil)
            }
        } catch {
            let msg = error.localizedDescription.lowercased()
            if msg.contains("email") && msg.contains("not confirmed") {
                errorMessage = "Debes confirmar tu correo antes de iniciar sesión. Revisa tu bandeja."
            } else {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            print("❌ Error al iniciar sesión:", error)
        }
    }

    // MARK: - Reset password
    func enviarCorreoRecuperacion() async {
        resetInfoMessage = nil
        let mail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !mail.isEmpty else {
            resetInfoMessage = "Introduce tu correo."
            return
        }
        guard isValidEmail(mail) else {
            resetInfoMessage = "Correo no válido."
            return
        }

        resetInFlight = true
        defer { resetInFlight = false }

        do {
            // Redirige a tu página pública de reset (opción A)
            let redirect = URL(string: "https://www.zymetrik.com/reset-password")!
            try await SupabaseManager.shared.client.auth.resetPasswordForEmail(mail, redirectTo: redirect)

            // No revelamos si el correo existe
            resetInfoMessage = "Si el correo existe, te enviamos un enlace para restablecer la contraseña."
        } catch {
            let lower = error.localizedDescription.lowercased()
            if lower.contains("requires an email") {
                resetInfoMessage = "Introduce un correo electrónico válido."
            } else if lower.contains("rate") || lower.contains("too many") {
                resetInfoMessage = "Has hecho demasiadas solicitudes. Inténtalo de nuevo en unos minutos."
            } else if lower.contains("not found") || lower.contains("no user") {
                resetInfoMessage = "Si el correo existe, recibirás el enlace. Verifica que esté bien escrito."
            } else if lower.contains("network") || lower.contains("internet") {
                resetInfoMessage = "Parece que no hay conexión. Inténtalo de nuevo."
            } else {
                resetInfoMessage = "No se pudo enviar el correo: \(error.localizedDescription)"
            }
            print("❌ resetPasswordForEmail:", error)
        }
    }

    // MARK: - Util
    private func isValidEmail(_ s: String) -> Bool {
        let regex = #"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$"#
        return s.range(of: regex, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
