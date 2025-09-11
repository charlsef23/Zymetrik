import SwiftUI
import PhotosUI
import Supabase

struct EditarPerfilView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var nombre: String
    @Binding var username: String
    @Binding var presentacion: String
    @Binding var enlaces: String
    @Binding var imagenPerfilURL: String?
    
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header con avatar mejorado
                    avatarSection
                    
                    // Campos de edición con diseño mejorado
                    profileFieldsSection
                    
                    // Información adicional
                    infoSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                    } else {
                        Button("Guardar") {
                            Task { await guardarCambios() }
                        }
                        .fontWeight(.semibold)
                        .disabled(isFormInvalid)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Guardado", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Tu perfil se ha actualizado correctamente")
            }
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 16) {
            Text("Foto de perfil")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            EnhancedAvatarPicker(
                currentImageURL: imagenPerfilURL,
                onImageSelected: { editedImage in
                    Task { await uploadNewAvatar(editedImage) }
                },
                size: 120
            )
            
            Text("Toca para cambiar tu foto de perfil")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Profile Fields Section
    private var profileFieldsSection: some View {
        VStack(spacing: 24) {
            Text("Información personal")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Campo Nombre
                ProfileFieldView(
                    title: "Nombre",
                    value: $nombre,
                    placeholder: "Tu nombre completo",
                    isRequired: true
                )
                
                // Campo Username
                ProfileFieldView(
                    title: "Nombre de usuario",
                    value: $username,
                    placeholder: "nombreusuario",
                    isRequired: true,
                    prefix: "@"
                )
                
                // Campo Presentación
                ProfileTextAreaView(
                    title: "Presentación",
                    value: $presentacion,
                    placeholder: "Cuéntanos sobre ti...",
                    maxCharacters: 150
                )
                
                // Campo Enlaces
                ProfileFieldView(
                    title: "Enlaces",
                    value: $enlaces,
                    placeholder: "https://tu-sitio-web.com",
                    keyboardType: .URL
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Tu perfil es público y otros usuarios pueden verlo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Tus datos están protegidos y seguros")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    private var isFormInvalid: Bool {
        nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        username.count < 3
    }
    
    // MARK: - Upload Avatar
    private func uploadNewAvatar(_ image: UIImage) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString
            
            // Subir avatar (normaliza a JPEG, guarda en perfil y notifica)
            let newURL = try await SupabaseAvatarManager.shared.uploadAvatarAndNotify(image, userID: userID)
            
            await MainActor.run {
                imagenPerfilURL = newURL
            }
            HapticManager.shared.success()
        } catch {
            await MainActor.run {
                errorMessage = "Error al subir la imagen: \(error.localizedDescription)"
                showError = true
            }
            HapticManager.shared.error()
        }
    }
    
    // MARK: - Save Changes
    /// Payload para update: `avatar_url` opcional → si es `nil` se envía `null` (no `""`)
    private struct PerfilUpdate: Encodable {
        let nombre: String
        let username: String
        let presentacion: String
        let enlaces: String
        let avatar_url: String?
    }
    
    private func guardarCambios() async {
        isSaving = true
        defer { isSaving = false }
        
        // Validar datos (usa tu struct existente)
        let datos = PerfilActualizado(
            nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            presentacion: presentacion.trimmingCharacters(in: .whitespacesAndNewlines),
            enlaces: enlaces.trimmingCharacters(in: .whitespacesAndNewlines),
            avatar_url: imagenPerfilURL
        )
        
        let (esValido, errores) = datos.validar()
        if !esValido {
            await MainActor.run {
                errorMessage = errores.joined(separator: "\n")
                showError = true
            }
            HapticManager.shared.error()
            return
        }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString
            
            let payload = PerfilUpdate(
                nombre: datos.nombre,
                username: datos.username,
                presentacion: datos.presentacion,
                enlaces: datos.enlaces,
                avatar_url: datos.avatar_url // nil → se serializa como null
            )
            
            try await SupabaseManager.shared.client
                .from("perfil")
                .update(payload)
                .eq("id", value: userID)
                .execute()
            
            await MainActor.run { showSuccess = true }
            HapticManager.shared.success()
        } catch {
            await MainActor.run {
                errorMessage = "Error al guardar: \(error.localizedDescription)"
                showError = true
            }
            HapticManager.shared.error()
        }
    }
}

// MARK: - Profile Field Components (tus componentes existentes)

struct ProfileFieldView: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    var isRequired: Bool = false
    var prefix: String? = nil
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*").foregroundColor(.red)
                }
                
                Spacer()
                
                if title == "Nombre de usuario" {
                    Text("\(value.count)/30")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundColor(.secondary)
                        .font(.body)
                }
                
                TextField(placeholder, text: $value)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .URL ? .none : .words)
                    .disableAutocorrection(keyboardType == .URL)
                    .onChange(of: value) { _, newValue in
                        if title == "Nombre de usuario" {
                            // Limitar caracteres y solo alfanum + "_"
                            let filtered = String(newValue.prefix(30).filter { $0.isLetter || $0.isNumber || $0 == "_" })
                            if filtered != newValue { value = filtered }
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct ProfileTextAreaView: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let maxCharacters: Int
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(value.count)/\(maxCharacters)")
                    .font(.caption2)
                    .foregroundColor(value.count > maxCharacters ? .red : .secondary)
            }
            
            TextField(placeholder, text: $value, axis: .vertical)
                .focused($isFocused)
                .lineLimit(4, reservesSpace: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
                .onChange(of: value) { _, newValue in
                    if newValue.count > maxCharacters {
                        value = String(newValue.prefix(maxCharacters))
                    }
                }
        }
    }
}
