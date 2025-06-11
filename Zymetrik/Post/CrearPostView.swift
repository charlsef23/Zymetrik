import SwiftUI

struct CrearPostView: View {
    @Environment(\.dismiss) var dismiss

    @State private var titulo: String = ""
    @State private var nuevoEjercicio: String = ""
    @State private var ejercicios: [String] = []

    var onPostCreado: ((EntrenamientoPost) -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nuevo entrenamiento")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Título
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Título")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("Ej. Pecho y tríceps", text: $titulo)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Ejercicios
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ejercicios")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        ForEach(ejercicios, id: \.self) { ejercicio in
                            HStack {
                                Text("• \(ejercicio)")
                                Spacer()
                                Button(action: {
                                    ejercicios.removeAll { $0 == ejercicio }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        HStack {
                            TextField("Añadir ejercicio", text: $nuevoEjercicio)
                                .textInputAutocapitalization(.never)
                            Button("Añadir") {
                                if !nuevoEjercicio.trimmingCharacters(in: .whitespaces).isEmpty {
                                    ejercicios.append(nuevoEjercicio)
                                    nuevoEjercicio = ""
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Botón publicar
                    Button(action: publicarPost) {
                        Text("Publicar")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(titulo.isEmpty || ejercicios.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Crear publicación")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func publicarPost() {
        let nuevoPost = EntrenamientoPost(
            usuario: "@carlos", // ← Luego cambiar por usuario real
            fecha: Date(),
            titulo: titulo,
            ejercicios: ejercicios
        )

        onPostCreado?(nuevoPost)
        dismiss()
    }
}
