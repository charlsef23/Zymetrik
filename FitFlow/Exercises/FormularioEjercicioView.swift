import SwiftUI
import SwiftData

struct FormularioEjercicioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var favoritos: [FavoriteExercise]

    var sesion: WorkoutSession
    var ejercicioExistente: ExerciseEntry?

    @State private var nombre: String = ""
    @State private var categoria: String = ""
    @State private var sets: [ExerciseSet] = []

    @State private var reps = ""
    @State private var peso = ""

    @State private var mostrarFavoritos = false
    @State private var favoritoAEliminar: FavoriteExercise?
    @State private var mostrarAlertaEliminar = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ejercicio")) {
                    TextField("Nombre del ejercicio", text: $nombre)
                    TextField("Categoría (Ej: Piernas, Pecho...)", text: $categoria)

                    if !nombre.isEmpty && !categoria.isEmpty {
                        Button("Guardar como favorito") {
                            guardarFavorito()
                        }
                    }
                }

                Section(header: Text("Series")) {
                    HStack {
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                        Text("x")
                        TextField("Peso (kg)", text: $peso)
                            .keyboardType(.decimalPad)
                        Button("➕") {
                            if let r = Int(reps), let p = Double(peso) {
                                sets.append(ExerciseSet(reps: r, weight: p))
                                reps = ""
                                peso = ""
                            }
                        }
                    }

                    ForEach(Array(sets.enumerated()), id: \.offset) { i, set in
                        let pesoFormateado = String(format: "%.1f", set.weight)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Serie \(i + 1)")
                                    .font(.headline)
                                Text("\(set.reps) reps x \(pesoFormateado) kg")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                sets.remove(at: i)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Section {
                    Button(ejercicioExistente == nil ? "Guardar" : "Actualizar") {
                        if let ejercicio = ejercicioExistente {
                            ejercicio.name = nombre
                            ejercicio.sets = sets
                        } else {
                            let nuevo = ExerciseEntry(name: nombre)
                            nuevo.sets = sets
                            sesion.exercises.append(nuevo)
                        }
                        try? sesion.modelContext?.save()
                        dismiss()
                    }
                    .disabled(nombre.isEmpty || sets.isEmpty)
                }
            }
            .navigationTitle(ejercicioExistente == nil ? "Nuevo ejercicio" : "Editar ejercicio")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        mostrarFavoritos = true
                    } label: {
                        Image(systemName: "star")
                    }
                }
            }
            .onAppear {
                if let ejercicio = ejercicioExistente {
                    nombre = ejercicio.name
                    sets = ejercicio.sets
                }
            }
            .sheet(isPresented: $mostrarFavoritos) {
                FavoritosEjerciciosView(onSeleccionar: { favorito in
                    nombre = favorito.name
                    categoria = favorito.category
                    mostrarFavoritos = false
                })
            }
        }
    }

    private func guardarFavorito() {
        guard !favoritos.contains(where: { $0.name.lowercased() == nombre.lowercased() && $0.category.lowercased() == categoria.lowercased() }) else { return }
        let nuevo = FavoriteExercise(name: nombre, category: categoria)
        context.insert(nuevo)
        try? context.save()
    }
}
