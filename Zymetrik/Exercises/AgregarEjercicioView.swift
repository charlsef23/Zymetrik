import SwiftUI
import SwiftData

struct AgregarEjercicioView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var sesion: WorkoutSession

    @State private var nombre = ""
    @State private var sets: [ExerciseSet] = []

    @State private var reps = ""
    @State private var peso = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ejercicio")) {
                    TextField("Nombre del ejercicio", text: $nombre)
                }

                Section(header: Text("Añadir series")) {
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
                        Text("Serie \(i+1): \(set.reps) reps x \(pesoFormateado) kg")
                    }
                }

                Section {
                    Button("Guardar ejercicio") {
                        let ejercicio = ExerciseEntry(name: nombre)
                        ejercicio.sets = sets
                        sesion.exercises.append(ejercicio)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(nombre.isEmpty || sets.isEmpty)
                }
            }
            .navigationTitle("Nuevo ejercicio")
        }
    }
}
