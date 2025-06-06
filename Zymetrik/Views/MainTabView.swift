import SwiftUI

struct MainTabView: View {
    let entrenamientosDemo: [SesionEntrenamiento] = [
        SesionEntrenamiento(
            titulo: "Pecho & Tríceps",
            fecha: Date(),
            ejercicios: [
                EjercicioEntrenamiento(nombre: "Press Banca", tipo: .fuerza, sets: [SetEjercicio(peso: "80", repeticiones: "8")]),
                EjercicioEntrenamiento(nombre: "Fondos", tipo: .fuerza, sets: [SetEjercicio(peso: "Corporal", repeticiones: "12")])
            ]
        )
    ]

    var body: some View {
        TabView {
            SocialFeedView(sesiones: entrenamientosDemo)
                .tabItem {
                    Image(systemName: "house.fill")
                }

            BuscarView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }

            CrearPostView()
                .tabItem {
                    Image(systemName: "plus.app")
                }

            EntrenamientoView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                }

            PerfilView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                }
        }
        .accentColor(.black)
    }
}

#Preview {
    MainTabView()
}
