import SwiftUI

struct PerfilEntrenamientosView: View {
    // Simulación de entrenamientos del usuario actual
    let entrenamientos: [EntrenamientoPost] = [
        EntrenamientoPost(
            usuario: "@Usuario",
            fecha: Date(),
            titulo: "Pecho y tríceps",
            ejercicios: [
                EjercicioPost(nombre: "Press banca", series: 4, repeticionesTotales: 32, pesoTotal: 320),
                EjercicioPost(nombre: "Aperturas", series: 3, repeticionesTotales: 30, pesoTotal: 150),
                EjercicioPost(nombre: "Fondos", series: 3, repeticionesTotales: 24, pesoTotal: 0)
            ],
            mediaURL: nil
        ),
        EntrenamientoPost(
            usuario: "@Usuario",
            fecha: Date(),
            titulo: "Pierna completa",
            ejercicios: [
                EjercicioPost(nombre: "Sentadilla", series: 4, repeticionesTotales: 40, pesoTotal: 500),
                EjercicioPost(nombre: "Prensa", series: 3, repeticionesTotales: 36, pesoTotal: 600),
                EjercicioPost(nombre: "Extensión de cuádriceps", series: 4, repeticionesTotales: 40, pesoTotal: 200)
            ],
            mediaURL: nil
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(entrenamientos) { post in
                    PostView(post: post)
                }
            }
            .padding(.top)
        }
    }
}
#Preview {
    PerfilEntrenamientosView()
}
