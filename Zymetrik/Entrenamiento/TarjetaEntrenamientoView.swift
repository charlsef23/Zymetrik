import SwiftUI

struct TarjetaEntrenamientoView: View {
    var entrenamiento: Entrenamiento
    var fecha: String
    var esHoy: Bool = false
    var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entrenamiento.nombre)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(fecha)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }

                Spacer()

                if esHoy {
                    Text("HOY")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(color.opacity(0.15)))
                        .foregroundColor(color)
                }
            }

            Divider()

            HStack(spacing: 24) {
                resumenDato("Ejercicios", "\(entrenamiento.ejercicios.count)")
                resumenDato("Series", "\(entrenamiento.ejercicios.map { $0.series }.reduce(0, +))")
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [color.opacity(0.05), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 4)
        .padding(.horizontal)
    }

    func resumenDato(_ titulo: String, _ valor: String) -> some View {
        VStack(spacing: 2) {
            Text(valor)
                .font(.headline)
                .foregroundColor(.primary)
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        TarjetaEntrenamientoView(
            entrenamiento: Entrenamiento(
                nombre: "Pecho y tríceps",
                ejercicios: [
                    Ejercicio(nombre: "Press banca", series: 4, repeticiones: 10, peso: 60),
                    Ejercicio(nombre: "Fondos", series: 3, repeticiones: 12, peso: 0)
                ]
            ),
            fecha: "Hoy",
            esHoy: true,
            color: .purple
        )
        TarjetaEntrenamientoView(
            entrenamiento: Entrenamiento(
                nombre: "Piernas",
                ejercicios: [
                    Ejercicio(nombre: "Sentadillas", series: 5, repeticiones: 10, peso: 80)
                ]
            ),
            fecha: "Ayer",
            color: .green
        )
    }
}
