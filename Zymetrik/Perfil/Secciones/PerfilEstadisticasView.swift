import SwiftUI

struct PerfilEstadisticasView: View {
    /// Si nil => estadísticas del usuario autenticado. Si no, del perfil indicado.
    let perfilId: UUID?

    @State private var ejerciciosConSesiones: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] = []
    @State private var cargando = true
    @State private var ejerciciosAbiertos: Set<UUID> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                if cargando {
                    ProgressView("Cargando…")
                        .padding(.vertical, 24)
                } else if ejerciciosConSesiones.isEmpty {
                    Text("No hay ejercicios con datos.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(ejerciciosConSesiones, id: \.ejercicio.id) { par in
                        EstadisticaEjercicioCard(
                            ejercicio: par.ejercicio,
                            perfilId: perfilId,
                            ejerciciosAbiertos: $ejerciciosAbiertos
                        )
                        // No añadimos overlays/bordes aquí
                    }
                }
            }
            .padding(.vertical, 12)          // sin padding horizontal → full-bleed
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await cargarTodasLasEstadisticas() }
    }

    func cargarTodasLasEstadisticas() async {
        cargando = true
        do {
            let autorId: UUID = try await {
                if let perfilId { return perfilId }
                return try await SupabaseService.shared.client.auth.session.user.id
            }()

            let posts = try await SupabaseService.shared.fetchPostsDelUsuario(autorId: autorId)

            var uniqueIds = Set<UUID>()
            var metaById: [UUID: EjercicioPostContenido] = [:]
            for post in posts {
                for e in post.contenido {
                    uniqueIds.insert(e.id)
                    if metaById[e.id] == nil { metaById[e.id] = e }
                }
            }

            if uniqueIds.isEmpty {
                await MainActor.run {
                    ejerciciosConSesiones = []
                    cargando = false
                }
                return
            }

            var acumulado: [(EjercicioPostContenido, [SesionEjercicio])] = []

            // Usa versión cacheada/tolerante
            await withTaskGroup(of: (UUID, [SesionEjercicio]).self) { group in
                for id in uniqueIds {
                    group.addTask {
                        let sesiones = await SupabaseService.shared
                            .obtenerSesionesParaCached(ejercicioID: id, autorId: autorId)
                        return (id, sesiones)
                    }
                }
                for await (id, sesiones) in group {
                    if !sesiones.isEmpty, let meta = metaById[id] {
                        acumulado.append((meta, sesiones))
                    }
                }
            }

            acumulado.sort { ($0.1.last?.fecha ?? .distantPast) > ($1.1.last?.fecha ?? .distantPast) }

            await MainActor.run {
                ejerciciosConSesiones = acumulado.map { (ej, ses) in (ejercicio: ej, sesiones: ses) }
                cargando = false
            }
        } catch {
            print("❌ Error al cargar estadísticas: \(error)")
            await MainActor.run { cargando = false }
        }
    }
}
