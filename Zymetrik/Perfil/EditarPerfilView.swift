import SwiftUI

struct EditarPerfilView: View {
    @Environment(\.dismiss) var dismiss

    @State private var nombreUsuario: String = "Carlitos"
    @State private var bio: String = "📱 Creador de @zymetrik.app\n👨🏻‍💻 Apple Developer · SwiftUI "
    @State private var mostrarSelectorFoto = false
    @State private var imagenPerfil: Image? = Image(systemName: "person.circle.fill")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Foto de perfil
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            imagenPerfil?
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .foregroundColor(.gray)

                            Button {
                                mostrarSelectorFoto = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: -6, y: -6)
                        }

                        Text("Cambiar foto")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Campos de edición
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nombre")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Nombre de usuario", text: $nombreUsuario)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Biografía")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $bio)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    Spacer()

                    // Botón guardar
                    Button {
                        // Guardar cambios y cerrar
                        dismiss()
                    } label: {
                        Text("Guardar cambios")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
