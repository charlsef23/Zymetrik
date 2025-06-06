import SwiftUI

struct EjercicioCardCompactView: View {
    let ejercicio: EjercicioEntrenamiento

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ejercicio.nombre)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                if ejercicio.tipo == .fuerza {
                    Text("💪 \(ejercicio.sets.count) sets")
                } else {
                    let tiempo = ejercicio.sets.first?.tiempo ?? "0"
                    let distancia = ejercicio.sets.first?.distancia ?? "-"
                    Text("🏃 \(tiempo) min / \(distancia) km")
                }
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
