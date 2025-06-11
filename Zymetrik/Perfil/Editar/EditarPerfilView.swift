import SwiftUI

struct EditarPerfilView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var nombre: String
    @Binding var username: String
    @Binding var presentacion: String
    @Binding var enlaces: String
    @Binding var imagenPerfil: Image?

    @State private var mostrarSelectorFoto = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Foto editable
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

                    // Secciones
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
                    Button("Guardar") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
}
