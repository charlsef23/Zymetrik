import SwiftUI
import PhotosUI
import Supabase

struct PerfilActualizado: Codable {
    let nombre: String
    let username: String
    let presentacion: String
    let enlaces: String
    let avatar_url: String?
}

enum SheetActivo: Identifiable {
    case selectorFoto
    case editorImagen(UIImage)

    var id: String {
        switch self {
        case .selectorFoto: return "selectorFoto"
        case .editorImagen: return "editorImagen"
        }
    }
}

struct EditarPerfilView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var nombre: String
    @Binding var username: String
    @Binding var presentacion: String
    @Binding var enlaces: String
    @Binding var imagenPerfilURL: String?

    @State private var selectedItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var sheetActivo: SheetActivo?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            if let urlString = imagenPerfilURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                    } else {
                                        fallbackAvatar
                                    }
                                }
                            } else {
                                fallbackAvatar
                            }

                            Button {
                                sheetActivo = .selectorFoto
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
            .sheet(item: $sheetActivo) { sheet in
                switch sheet {
                case .selectorFoto:
                    PhotosPicker("Seleccionar imagen", selection: $selectedItem, matching: .images)
                        .padding()
                        .onChange(of: selectedItem) {
                            if let newItem = selectedItem {
                                Task {
                                    await cargarImagenParaEditar(newItem)
                                }
                            }
                        }

                case .editorImagen(let uiImage):
                    ImageEditorView(
                        originalImage: uiImage,
                        onConfirm: { imagenRecortada in
                            Task {
                                await subirImagenEditada(imagenRecortada)
                            }
                            sheetActivo = nil
                        },
                        onCancel: {
                            sheetActivo = nil
                        }
                    )
                }
            }
        }
    }

    private var fallbackAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .foregroundColor(.gray)
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

    func cargarImagenParaEditar(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }

            await MainActor.run {
                sheetActivo = .editorImagen(uiImage)
            }
        } catch {
            print("❌ Error cargando imagen: \(error)")
        }
    }

    func subirImagenEditada(_ imagen: UIImage) async {
        do {
            guard let compressedData = imagen.jpegData(compressionQuality: 0.8) else { return }

            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString
            let fileName = "avatar_\(userID).jpg"
            let storagePath = "usuarios/\(fileName)"

            _ = try await SupabaseManager.shared.client.storage
                .from("avatars")
                .upload(
                    storagePath,
                    data: compressedData,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )

            let publicURL = try SupabaseManager.shared.client.storage
                .from("avatars")
                .getPublicURL(path: storagePath)

            await MainActor.run {
                imagenPerfilURL = publicURL.absoluteString
            }

        } catch {
            print("❌ Error al subir imagen editada: \(error)")
        }
    }

    func guardarCambios() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString

            let datos = PerfilActualizado(
                nombre: nombre,
                username: username,
                presentacion: presentacion,
                enlaces: enlaces,
                avatar_url: imagenPerfilURL ?? ""
            )

            _ = try await SupabaseManager.shared.client
                .from("perfil")
                .update(datos)
                .eq("id", value: userID)
                .execute()

            await MainActor.run {
                dismiss()
            }

        } catch {
            print("❌ Error al guardar perfil: \(error)")
        }
    }
}
