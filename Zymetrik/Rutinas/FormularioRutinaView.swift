import SwiftUI
import SwiftData

struct FormularioRutinaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var nombreRutina: String = ""
    @State private var ejercicios: [RoutineExercise] = []
    @State private var nuevoNombreEjercicio: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Nombre de la rutina")) {
                    TextField("Ej: Full Body", text: $nombreRutina)
                }

                Section(header: Text("Ejercicios añadidos")) {
                    if ejercicios.isEmpty {
                        Text("Añade ejercicios para esta rutina.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(ejercicios.indices, id: \.self) { i in
                            HStack {
                                Text(ejercicios[i].name)
                                Spacer()
                                Button(role: .destructive) {
                                    ejercicios.remove(at: i)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Añadir ejercicio")) {
                    TextField("Nombre del ejercicio", text: $nuevoNombreEjercicio)

                    Button("Añadir") {
                        let nuevo = RoutineExercise(name: nuevoNombreEjercicio)
                        ejercicios.append(nuevo)
                        nuevoNombreEjercicio = ""
                    }
                    .disabled(nuevoNombreEjercicio.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section {
                    Button("Guardar rutina") {
                        let nueva = Routine(name: nombreRutina)
                        nueva.exercises = ejercicios
                        context.insert(nueva)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(nombreRutina.trimmingCharacters(in: .whitespaces).isEmpty || ejercicios.isEmpty)
                }
            }
            .navigationTitle("Nueva rutina")
        }
    }
}
