import SwiftUI

struct PerfilEstadisticasView: View {
    @State private var ejerciciosConSesiones: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] = []
    @State private var cargando = true
    @State private var ejerciciosAbiertos: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if cargando {
                    ProgressView("Cargando...")
                        .padding()
                } else if ejerciciosConSesiones.isEmpty {
                    Text("No hay ejercicios con datos.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(ejerciciosConSesiones, id: \.ejercicio.id) { par in
                        EstadisticaEjercicioCard(
                            ejercicio: par.ejercicio,
                            sesiones: par.sesiones,
                            ejerciciosAbiertos: $ejerciciosAbiertos
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color.white.ignoresSafeArea())
        .task {
            await cargarTodasLasEstadisticas()
        }
    }

    func cargarTodasLasEstadisticas() async {
        cargando = true
        do {
            let posts = try await SupabaseService.shared.fetchPosts()
            var agrupado: [UUID: (ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] = [:]

            for post in posts {
                for ejercicio in post.contenido {
                    let sesiones = try await SupabaseService.shared.obtenerSesionesPara(ejercicioID: ejercicio.id)
                    if !sesiones.isEmpty {
                        if var existente = agrupado[ejercicio.id] {
                            existente.sesiones += sesiones
                            agrupado[ejercicio.id] = existente
                        } else {
                            agrupado[ejercicio.id] = (ejercicio, sesiones)
                        }
                    }
                }
            }

            // Convertir a array
            let resultado = Array(agrupado.values)

            await MainActor.run {
                ejerciciosConSesiones = resultado
                cargando = false
            }
        } catch {
            print("❌ Error al cargar estadísticas: \(error)")
            cargando = false
        }
    }
}
