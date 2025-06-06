import SwiftUI

struct EjercicioAcordeonView: View {
    @Binding var ejercicio: EjercicioEntrenamiento
    @State private var expandido = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ejercicio.nombre)
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation {
                        expandido.toggle()
                    }
                }) {
                    Image(systemName: expandido ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }

            if expandido {
                VStack(spacing: 10) {
                    ForEach($ejercicio.sets) { $set in
                        if ejercicio.tipo == .fuerza {
                            HStack(spacing: 12) {
                                TextField("Peso (kg)", text: $set.peso)
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)

                                TextField("Reps", text: $set.repeticiones)
                                    .keyboardType(.numberPad)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        } else if ejercicio.tipo == .cardio {
                            HStack(spacing: 12) {
                                TextField("Tiempo (min)", text: $set.tiempo)
                                    .keyboardType(.numberPad)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)

                                TextField("Distancia (km)", text: $set.distancia)
                                    .keyboardType(.decimalPad)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Button(action: {
                        ejercicio.sets.append(SetEjercicio())
                    }) {
                        Label("Añadir set", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
