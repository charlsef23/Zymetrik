import SwiftUI
import SwiftData

struct PerfilView: View {
    @Query private var usuarios: [User]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var nombreEditado = ""

    var body: some View {
        NavigationStack {
            Form {
                if let usuario = usuarios.first {
                    Section(header: Text("Información del Usuario")) {
                        TextField("Nombre", text: $nombreEditado)
                            .onAppear {
                                nombreEditado = usuario.name
                            }

                        HStack {
                            Text("Email")
                            Spacer()
                            Text(usuario.email)
                                .foregroundColor(.gray)
                        }
                    }

                    Section {
                        Button("Guardar cambios") {
                            usuario.name = nombreEditado
                            try? context.save()
                        }

                        Button(role: .destructive) {
                            cerrarSesion(usuario: usuario)
                        } label: {
                            Text("Cerrar sesión")
                        }
                    }
                } else {
                    Text("No hay ningún perfil cargado.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Mi perfil")
        }
    }

    private func cerrarSesion(usuario: User) {
        // Eliminar de SwiftData (iCloud)
        context.delete(usuario)
        try? context.save()

        // Borrar del almacenamiento local
        userName = ""
        userEmail = ""

        // Volver atrás
        dismiss()
    }
}
