import SwiftUI

struct EntrenandoView: View {
    let ejercicios: [Ejercicio]
    @State private var setsPorEjercicio: [UUID: [SetRegistro]] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(ejercicios) { ejercicio in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(ejercicio.nombre)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(setsPorEjercicio[ejercicio.id] ?? [], id: \.id) { set in
                            HStack {
                                Text("Set \(set.numero)")
                                Spacer()
                                Text("\(set.repeticiones) reps · \(set.peso) kg")
                            }
                            .padding(.horizontal)
                        }

                        Button(action: {
                            var nuevosSets = setsPorEjercicio[ejercicio.id] ?? []
                            let nuevo = SetRegistro(
                                id: UUID(),
                                numero: nuevosSets.count + 1,
                                repeticiones: 10,
                                peso: 0
                            )
                            nuevosSets.append(nuevo)
                            setsPorEjercicio[ejercicio.id] = nuevosSets
                        }) {
                            Label("Añadir set", systemImage: "plus")
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Entrenando")
    }
}

// Modelo temporal para sets
struct SetRegistro: Identifiable {
    let id: UUID
    let numero: Int
    var repeticiones: Int
    var peso: Double
}
