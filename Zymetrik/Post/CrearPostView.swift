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

                    // Ejercicios seleccionados
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Ejercicios")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                mostrarSelector = true
                            }) {
                                Label("Añadir", systemImage: "plus.circle")
                                    .font(.subheadline)
                            }
                        }

                        ForEach(ejercicios, id: \.id) { ejercicio in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ejercicio.nombre)
                                        .font(.headline)
                                    Text("Series: \(ejercicio.series ?? 0), Reps: \(ejercicio.repeticionesTotales ?? 0), Peso: \(ejercicio.pesoTotal ?? 0, specifier: "%.1f") kg")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Button(action: {
                                    ejercicios.removeAll { $0.id == ejercicio.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Botón publicar
                    Button(action: publicarPost) {
                        Text("Publicar")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(titulo.isEmpty || ejercicios.isEmpty ? Color.gray : Color.black)
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
        let ejerciciosPost = ejercicios.map {
            EjercicioPost(
                nombre: $0.nombre,
                series: $0.series ?? 0,
                repeticionesTotales: $0.repeticionesTotales ?? 0,
                pesoTotal: $0.pesoTotal ?? 0.0
            )
        }

        let nuevoPost = EntrenamientoPost(
            usuario: "@carlos",
            fecha: Date(),
            titulo: titulo,
            ejercicios: ejerciciosPost,
            mediaURL: nil // Puedes incluir un selector de imagen más adelante
        )

        onPostCreado?(nuevoPost)
        dismiss()
    }
}

struct ListaEjerciciosSeleccionarView: View {
    @Binding var ejerciciosSeleccionados: [Ejercicio]
    @Environment(\.dismiss) var dismiss

    // Simulación de una lista de ejercicios
    let todosLosEjercicios: [Ejercicio] = [
        Ejercicio(nombre: "Press banca", descripcion: "Ejercicio de pecho", categoria: "Pecho", tipo: .gimnasio),
        Ejercicio(nombre: "Sentadilla", descripcion: "Piernas", categoria: "Piernas", tipo: .gimnasio),
        Ejercicio(nombre: "Cinta", descripcion: "Cardio clásico", categoria: "Cardio", tipo: .cardio)
    ]

    @State private var seleccionados: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(todosLosEjercicios, id: \.id) { ejercicio in
                Button {
                    if seleccionados.contains(ejercicio.id) {
                        seleccionados.remove(ejercicio.id)
                    } else {
                        seleccionados.insert(ejercicio.id)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ejercicio.nombre)
                                .fontWeight(.semibold)
                            Text(ejercicio.descripcion)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if seleccionados.contains(ejercicio.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Seleccionar ejercicios")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        ejerciciosSeleccionados = todosLosEjercicios.filter {
                            seleccionados.contains($0.id)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
