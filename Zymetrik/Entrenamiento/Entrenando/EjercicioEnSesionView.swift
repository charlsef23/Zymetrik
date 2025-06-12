import SwiftUI

struct EjercicioEnSesionView: View {
    let ejercicio: Ejercicio
    @State private var sets: [SetEjercicio] = []
    @State private var repeticiones: String = ""
    @State private var peso: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ejercicio.nombre)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(ejercicio.descripcion)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: iconoParaTipo(ejercicio.tipo))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.5))
            }

            Divider().background(.white.opacity(0.5))

            // Sets
            VStack(spacing: 10) {
                ForEach(sets.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))

                        Spacer()

                        Text("\(sets[index].reps) reps  •  \(sets[index].peso, specifier: "%.1f") kg")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }

            // Inputs
            HStack(spacing: 12) {
                TextField("Reps", text: $repeticiones)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .frame(width: 70)

                TextField("Kg", text: $peso)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .frame(width: 90)

                Button(action: {
                    if let reps = Int(repeticiones), let kg = Double(peso) {
                        sets.append(SetEjercicio(reps: reps, peso: kg))
                        repeticiones = ""
                        peso = ""
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Añadir")
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorFondo(ejercicio.tipo))
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    func iconoParaTipo(_ tipo: TipoEjercicio) -> String {
        switch tipo {
        case .gimnasio: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .funcional: return "figure.strengthtraining.traditional"
        }
    }

    func colorFondo(_ tipo: TipoEjercicio) -> Color {
        switch tipo {
        case .gimnasio: return Color(red: 0.21, green: 0.36, blue: 0.67) // azul fuerte
        case .cardio: return Color(red: 0.83, green: 0.33, blue: 0.25) // rojo coral
        case .funcional: return Color(red: 0.25, green: 0.67, blue: 0.45) // verde
        }
    }
}

struct SetEjercicio {
    var reps: Int
    var peso: Double
}
