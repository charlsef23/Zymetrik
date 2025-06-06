import SwiftUI

struct SesionCardView: View {
    let sesion: SesionEntrenamiento

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sesion.titulo)
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(sesion.ejercicios) { ejercicio in
                EjercicioCardCompactView(ejercicio: ejercicio)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}
