import SwiftUI

struct EjercicioEstadisticasView: View {
    let ejercicio: EjercicioPostContenido

    var body: some View {
        VStack(spacing: 16) {
            Text(ejercicio.nombre)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                StatView(title: "Series", value: "\(ejercicio.totalSeries)", color: .blue)
                StatView(title: "Reps", value: "\(ejercicio.totalRepeticiones)", color: .green)
                StatView(title: "Kg", value: String(format: "%.1f", ejercicio.totalPeso), color: .orange)
            }

            HStack(spacing: 16) {
                StatView(title: "Kg/Set", value: String(format: "%.1f", ejercicio.totalSeries > 0 ? ejercicio.totalPeso / Double(ejercicio.totalSeries) : 0), color: .pink)
                StatView(title: "Reps/Set", value: String(format: "%.1f", ejercicio.totalSeries > 0 ? Double(ejercicio.totalRepeticiones) / Double(ejercicio.totalSeries) : 0), color: .mint)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}
