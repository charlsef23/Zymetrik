import SwiftUI
import Supabase

struct RegistroView: View {
    var onSuccess: (() -> Void)? = nil

    @State private var nombre = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("LogoSinFondoNegro")
                .resizable().scaledToFit().frame(width: 100).padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("Crear cuenta").font(.title).fontWeight(.semibold)
                Text("Únete a la comunidad Zymetrik")
                    .font(.subheadline).foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                CustomTextField(placeholder: "Nombre", text: $nombre, icon: "person").frame(height: 45)
                CustomTextField(placeholder: "Nombre de usuario", text: $username, icon: "person").frame(height: 45)
                CustomTextField(placeholder: "Correo electrónico", text: $email, icon: "envelope")
                    .frame(height: 45).textInputAutocapitalization(.never).autocorrectionDisabled(true)
                CustomSecureField(placeholder: "Contraseña", text: $password).frame(height: 45)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red).font(.footnote).multilineTextAlignment(.center)
            }

            Button(action: { Task { await registrarse() } }) {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 45)
                } else {
                    Text("Registrarme")
                        .fontWeight(.medium).frame(maxWidth: .infinity).frame(height: 45)
                        .background(Color.white).foregroundColor(.black).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1))
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Registro + crear perfil
    func registrarse() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Por favor, completa todos los campos."
            return
        }

        do {
            // username único
            let resp = try await SupabaseManager.shared.client
                .from("perfil").select().eq("username", value: username).limit(1).execute()
            if let arr = try? JSONSerialization.jsonObject(with: resp.data) as? [[String: Any]], !arr.isEmpty {
                errorMessage = "El nombre de usuario ya está en uso."
                return
            }

            // alta + login
            _ = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
            _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)

            // perfil
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id
            try await SupabaseManager.shared.client
                .from("perfil")
                .insert(["id": userID.uuidString, "username": username, "nombre": nombre])
                .execute()

            // Navega y dispara el evento (AppDelegate gestiona permiso + OneSignal)
            DispatchQueue.main.async {
                onSuccess?()
                NotificationCenter.default.post(name: .didLoginSuccess, object: nil)
            }

        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            print("❌ Error en registro:", error)
        }
    }
}
