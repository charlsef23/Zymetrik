import SwiftUI
import Supabase

struct PerfilActualizado: Codable {
    let nombre: String
    let username: String
    let presentacion: String
    let enlaces: String
    let avatar_url: String?
}

struct EditarPerfilView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var nombre: String
    @Binding var username: String
    @Binding var presentacion: String
    @Binding var enlaces: String
    @Binding var imagenPerfil: Image?

    @State private var mostrarSelectorFoto = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            imagenPerfil?
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))

                            Button {
                                mostrarSelectorFoto = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Circle().fill(Color.black))
                            }
                            .offset(x: -6, y: -6)
                        }

                        Text("Cambiar foto")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)

                    VStack(spacing: 1) {
                        editableRow("Nombre", value: nombre) {
                            EditarCampoNombreView(nombre: $nombre)
                        }
                        editableRow("Nombre de usuario", value: username) {
                            EditarCampoUsernameView(username: $username)
                        }
                        editableRow("Presentación", value: presentacion) {
                            EditarCampoPresentacionView(presentacion: $presentacion)
                        }
                        editableRow("Enlaces", value: enlaces.isEmpty ? "Añadir enlaces" : enlaces) {
                            EditarCampoEnlacesView(enlaces: $enlaces)
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.02), radius: 1, y: 1)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Guardar") {
                            Task {
                                await guardarCambios()
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $mostrarSelectorFoto) {
                Text("Aquí irá el selector de imagen")
                    .padding()
            }
        }
    }

    func editableRow<Destination: View>(_ title: String, value: String, destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.vertical, 14)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white)
    }

    func guardarCambios() async {
        isSaving = true
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString

            var avatarURL: String? = nil

            // Subir imagen de perfil si existe
            if let imagenPerfil = imagenPerfil,
               let uiImage = convertImage(imagenPerfil),
               let imageData = uiImage.jpegData(compressionQuality: 0.8) {

                let fileName = "avatar_\(userID).jpg"
                let storagePath = "usuarios/\(fileName)" // ← Asegúrate de que esto coincida con la ruta pública
                let urlPublica = "https://rmpgmdokzwfqdzqmrqmj.supabase.co/storage/v1/object/public/avatars/\(storagePath)"

                // Subida real al bucket
                _ = try await SupabaseManager.shared.client
                    .storage
                    .from("avatars")
                    .upload(storagePath, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

                avatarURL = urlPublica
            }

            // Enviar datos actualizados
            let datos = PerfilActualizado(
                nombre: nombre,
                username: username,
                presentacion: presentacion,
                enlaces: enlaces,
                avatar_url: avatarURL ?? "" // 👈 así nunca es nil
            )

            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .update(datos)
                .eq("id", value: userID)
                .select()
                .single()
                .execute()

            print("✅ Perfil actualizado: \(response)")

            DispatchQueue.main.async {
                dismiss()
            }

        } catch {
            print("❌ Error al guardar perfil: \(error)")
        }
        isSaving = false
    }
}

func convertImage(_ image: Image?) -> UIImage? {
    guard let image = image else { return nil }
    let controller = UIHostingController(rootView: image)
    let view = controller.view

    let targetSize = CGSize(width: 200, height: 200)
    view?.bounds = CGRect(origin: .zero, size: targetSize)
    view?.backgroundColor = .clear

    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
    }
}
