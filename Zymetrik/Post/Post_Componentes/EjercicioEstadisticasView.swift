import SwiftUI


struct EjercicioEstadisticasView: View {
    let ejercicio: EjercicioPostContenido

    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(Color(UIColor.systemGray6))
            .frame(height: 180)
            .overlay(
                VStack(spacing: 16) {
                    Text(ejercicio.nombre)
                        .font(.title2.bold())

                    HStack(spacing: 32) {
                        StatView(title: "Series", value: "\(ejercicio.totalSeries)")
                        StatView(title: "Reps", value: "\(ejercicio.totalRepeticiones)")
                        StatView(title: "Kg", value: String(format: "%.1f", ejercicio.totalPeso))
                    }
                }
            )
    }
}
