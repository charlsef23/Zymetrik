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
    
    // UI
    @State private var showScrollShadow = false
    @Namespace private var focusNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerHero
                    avatarSection
                    profileFieldsSection
                    infoSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: OffsetPrefKey.self, value: geo.frame(in: .named("scroll")).minY)
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(OffsetPrefKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showScrollShadow = y < -8
                }
            }
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color(.systemGroupedBackground), location: 0),
                        .init(color: Color(.secondarySystemGroupedBackground), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    } label: {
                        Label("Cancelar", systemImage: "xmark")
                            .labelStyle(.titleAndIcon)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Editar perfil")
                        .font(.headline)
                        .opacity(0.9)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().scaleEffect(0.9).tint(.blue)
                    } else {
                        Button("Guardar") {
                            Task { await guardarCambios() }
                        }
                        .fontWeight(.semibold)
                        .disabled(isFormInvalid)
                        .opacity(isFormInvalid ? 0.5 : 1)
                        .overlay {
                            if !isFormInvalid {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                                    .blendMode(.overlay)
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            // Fallback a la sombra de la barra (sustituye a .toolbarShadow)
            .overlay(alignment: .top) {
                if showScrollShadow {
                    Divider()
                        .background(Color.black.opacity(0.15))
                        .ignoresSafeArea(edges: .top)
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
    
    // MARK: - Hero
    private var headerHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pon tu perfil a punto")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text("Actualiza tu nombre, usuario, bio y enlaces. Los cambios se verán al instante.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("Foto de perfil")
                    .font(.headline)
                Spacer()
            }
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
        }
        .padding(.top, 4)
    }
    
    // MARK: - Profile Fields Section
    private var profileFieldsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(.purple)
                Text("Información personal")
                    .font(.headline)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 14) {
                ProfileFieldView(
                    title: "Nombre",
                    value: $nombre,
                    placeholder: "Tu nombre completo",
                    isRequired: true
                )
                
                ProfileFieldView(
                    title: "Nombre de usuario",
                    value: $username,
                    placeholder: "nombreusuario",
                    isRequired: true,
                    prefix: "@"
                )
                
                ProfileTextAreaView(
                    title: "Presentación",
                    value: $presentacion,
                    placeholder: "Cuéntanos sobre ti...",
                    maxCharacters: 150
                )
                
                ProfileFieldView(
                    title: "Enlaces",
                    value: $enlaces,
                    placeholder: "https://tu-sitio-web.com",
                    keyboardType: .URL
                )
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 10) {
            infoLine(icon: "info.circle", color: .blue, text: "Tu perfil es público y otros usuarios pueden verlo")
            infoLine(icon: "lock.shield", color: .green, text: "Tus datos están protegidos y seguros")
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.06))
        )
    }
    
    private func infoLine(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Computed
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
            let newURL = try await SupabaseAvatarManager.shared.uploadAvatarAndNotify(image, userID: userID)
            await MainActor.run { imagenPerfilURL = newURL }
            HapticManager.shared.success()
        } catch {
            await MainActor.run {
                errorMessage = "Error al subir la imagen: \(error.localizedDescription)"
                showError = true
            }
            HapticManager.shared.error()
        }
    }
    
    // MARK: - Save Changes (sin cambios funcionales)
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
                avatar_url: datos.avatar_url
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

// MARK: - Floating Label Field

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
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if isRequired {
                    Text("•").foregroundColor(.red)
                }
                Spacer()
                if title == "Nombre de usuario" {
                    Text("\(value.count)/30")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.systemGray6)))
                        .overlay(Capsule().stroke(Color.primary.opacity(0.06)))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            
            ZStack(alignment: .leading) {
                // Caja base
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        // Borde degradado con opacidad (evita el ternario LinearGradient/Color)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.7)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .opacity(isFocused ? 1 : 0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFocused)
                    )
                    .shadow(color: isFocused ? .blue.opacity(0.12) : .clear, radius: 10, x: 0, y: 4)
                
                HStack(spacing: 8) {
                    if let prefix = prefix {
                        Text(prefix)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 12)
                    } else {
                        Spacer().frame(width: 12)
                    }
                    
                    TextField(placeholder, text: $value)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .URL ? .none : .words)
                        .disableAutocorrection(keyboardType == .URL)
                        .onChange(of: value) { _, newValue in
                            if title == "Nombre de usuario" {
                                let filtered = String(newValue.prefix(30).filter { $0.isLetter || $0.isNumber || $0 == "_" })
                                if filtered != newValue { value = filtered }
                            }
                        }
                        .padding(.vertical, 14)
                    
                    Spacer(minLength: 8)
                }
            }
        }
    }
}

// MARK: - Floating Label TextArea

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
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value.count)/\(maxCharacters)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.systemGray6)))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.06)))
                    .foregroundStyle(value.count > maxCharacters ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.7)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .opacity(isFocused ? 1 : 0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFocused)
                    )
                
                TextField(placeholder, text: $value, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(4, reservesSpace: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .onChange(of: value) { _, newValue in
                        if newValue.count > maxCharacters {
                            value = String(newValue.prefix(maxCharacters))
                        }
                    }
            }
        }
    }
}

// MARK: - Helpers

private struct OffsetPrefKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
