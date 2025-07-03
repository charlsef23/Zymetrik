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
                CustomTextField(placeholder: "Nombre", text: $nombre, icon: "person")
                    .frame(height: 45)
                
                CustomTextField(placeholder: "Nombre de usuario", text: $username, icon: "person")
                    .frame(height: 45)
                
                CustomTextField(placeholder: "Correo electrónico", text: $email, icon: "envelope")
                    .frame(height: 45)
                
                CustomSecureField(placeholder: "Contraseña", text: $password)
                    .frame(height: 45)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            VStack(spacing: 14) {
                Button(action: {
                    Task {
                        await registrarse()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 45)
                    } else {
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
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Registro en Supabase
    func registrarse() async {
        errorMessage = nil
        isLoading = true
        
        // Validar campos vacíos
        guard !nombre.isEmpty,
              !username.isEmpty,
              !email.isEmpty,
              !password.isEmpty else {
            errorMessage = "Por favor, completa todos los campos."
            isLoading = false
            return
        }
        
        do {
            // Verificar si el nombre de usuario ya existe
            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .select()
                .eq("username", value: username)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
               !jsonArray.isEmpty {
                errorMessage = "El nombre de usuario ya está en uso."
                isLoading = false
                return
            }
            
            // Registrar al usuario en Supabase Auth
            _ = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            
            // Iniciar sesión inmediatamente
            _ = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            
            // Obtener el ID del usuario (auth.uid())
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id
            
            // Insertar en la tabla "profiles"
            try await SupabaseManager.shared.client
                .from("perfil")
                .insert([
                    "id": userID.uuidString,
                    "username": username,
                    "nombre": nombre
                ])
                .execute()
            
            print("✅ Usuario registrado correctamente")
            
            // Navegar a la vista principal
            DispatchQueue.main.async {
                onSuccess?()
            }
            
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            print("❌ Error en registro: \(error)")
        }
        
        isLoading = false
    }
}
    
#Preview {
    RegistroView()
}
