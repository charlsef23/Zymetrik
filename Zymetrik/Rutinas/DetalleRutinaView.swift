import SwiftUI
import SwiftData

struct DetalleRutinaView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let rutina: Routine
    @State private var mostrarFecha = false
    @State private var fechaSeleccionada: Date = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(rutina.name)
                    .font(.largeTitle)
                    .bold()

                ForEach(rutina.exercises) { ejercicio in
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.blue)
                        Text(ejercicio.name)
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Button {
                    mostrarFecha = true
                } label: {
                    Label("Aplicar rutina a una fecha", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Rutina")
        .sheet(isPresented: $mostrarFecha) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker("Selecciona una fecha", selection: $fechaSeleccionada, displayedComponents: .date)

                    Button("Aplicar rutina") {
                        aplicarRutina()
                        mostrarFecha = false
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()
                .navigationTitle("Aplicar rutina")
            }
        }
    }

    func aplicarRutina() {
        let nuevaSesion = WorkoutSession(date: fechaSeleccionada, title: rutina.name)

        for ejercicioPlantilla in rutina.exercises {
            let ejercicio = ExerciseEntry(name: ejercicioPlantilla.name)
            ejercicio.sets = [] // se rellenarán el día del entrenamiento
            nuevaSesion.exercises.append(ejercicio)
        }

        context.insert(nuevaSesion)
        try? context.save()
    }
}
