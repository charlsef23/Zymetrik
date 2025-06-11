import SwiftUI

struct CrearPostView: View {
    @Environment(\.dismiss) var dismiss

    @State private var titulo: String = ""
    @State private var ejercicios: [Ejercicio] = []
    @State private var mostrarSelector = false

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
                        HStack {
                            Text("Ejercicios")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                mostrarSelector = true
                            }) {
                                Label("Seleccionar", systemImage: "plus.circle")
                                    .font(.subheadline)
                            }
                        }

                        ForEach(ejercicios, id: \.id) { ejercicio in
                            HStack {
                                Text("• \(ejercicio.nombre)")
                                Spacer()
                                Button(action: {
                                    ejercicios.removeAll { $0.id == ejercicio.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
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
            .sheet(isPresented: $mostrarSelector) {
                ListaEjerciciosSeleccionarView(ejerciciosSeleccionados: $ejercicios)
            }
        }
    }

    private func publicarPost() {
        let nuevoPost = EntrenamientoPost(
            usuario: "@carlos",
            fecha: Date(),
            titulo: titulo,
            ejercicios: ejercicios.map { $0.nombre }
        )

        onPostCreado?(nuevoPost)
        dismiss()
    }
}

struct ListaEjerciciosSeleccionarView: View {
    @Binding var ejerciciosSeleccionados: [Ejercicio]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ListaEjerciciosView(
            modoSeleccion: true,
            ejerciciosSeleccionadosBinding: $ejerciciosSeleccionados,
            onFinalizarSeleccion: { dismiss() }
        )
    }
}
