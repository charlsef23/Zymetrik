import SwiftUI
import SwiftData

struct DetalleSesionView: View {
    @Environment(\.modelContext) private var context
    @State private var mostrarFormulario = false
    @State private var ejercicioSeleccionado: ExerciseEntry?
    @State private var ejercicioAEliminar: ExerciseEntry?
    @State private var mostrarAlertaEliminar = false

    var sesion: WorkoutSession

    var body: some View {
        List {
            if sesion.exercises.isEmpty {
                Text("No hay ejercicios en esta sesión.")
                    .foregroundColor(.gray)
            } else {
                ForEach(sesion.exercises) { ejercicio in
                    Section(header: Text(ejercicio.name)) {
                        ForEach(ejercicio.sets.indices, id: \.self) { i in
                            let set = ejercicio.sets[i]
                            let pesoFormateado = String(format: "%.1f", set.weight)
                            Text("Serie \(i + 1): \(set.reps) reps x \(pesoFormateado) kg")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            ejercicioAEliminar = ejercicio
                            mostrarAlertaEliminar = true
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        ejercicioSeleccionado = ejercicio
                        mostrarFormulario = true
                    }
                }
            }
        }
        .navigationTitle(sesion.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    ejercicioSeleccionado = nil
                    mostrarFormulario = true
                } label: {
                    Label("Añadir ejercicio", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarFormulario) {
            FormularioEjercicioView(sesion: sesion, ejercicioExistente: ejercicioSeleccionado)
        }
        .alert("¿Eliminar ejercicio?", isPresented: $mostrarAlertaEliminar, actions: {
            Button("Eliminar", role: .destructive) {
                if let ejercicio = ejercicioAEliminar {
                    eliminarEjercicio(ejercicio)
                }
            }
            Button("Cancelar", role: .cancel) { }
        }, message: {
            Text("Esta acción no se puede deshacer.")
        })
    }

    private func eliminarEjercicio(_ ejercicio: ExerciseEntry) {
        sesion.exercises.removeAll { $0.id == ejercicio.id }
        context.delete(ejercicio)
        try? context.save()
    }
}
