import SwiftUI

struct PerfilEstadisticasView: View {
    /// Si nil => estadísticas del usuario autenticado. Si no, del perfil indicado.
    let perfilId: UUID?

    @State private var ejerciciosConSesiones: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] = []
    @State private var cargando = true
    @State private var ejerciciosAbiertos: Set<UUID> = []
    @State private var categoriaSeleccionada: String = "Todas"
    @State private var categoriasDisponibles: [String] = ["Todas"]

    var body: some View {
        ScrollView {
            // Filtro por categoría
            if !cargando {
                VStack(alignment: .leading, spacing: 10) {
                    // Desplegable de categorías
                    Menu {
                        // Opción Todas
                        Button(action: { categoriaSeleccionada = "Todas" }) {
                            Label("Todas", systemImage: categoriaSeleccionada == "Todas" ? "checkmark" : "")
                        }
                        Divider()
                        ForEach(categoriasDisponibles.filter { $0 != "Todas" }.sorted(), id: \.self) { cat in
                            Button(action: { categoriaSeleccionada = cat }) {
                                Label(cat, systemImage: categoriaSeleccionada == cat ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(categoriaSeleccionada)
                                .font(.body)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.primary.opacity(0.8))
                                .imageScale(.small)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.25), Color.pink.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.12), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(12)
                .padding(.horizontal)
                .padding(.top, 12)
            }
            LazyVStack(spacing: 16, pinnedViews: []) {
                if cargando {
                    ProgressView("Cargando…")
                        .padding(.vertical, 24)
                } else if ejerciciosConSesiones.isEmpty {
                    Text("No hay ejercicios con datos.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(filtradosPorCategoria(), id: \.ejercicio.id) { par in
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

    private func filtradosPorCategoria() -> [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] {
        if categoriaSeleccionada == "Todas" { return ejerciciosConSesiones }
        return ejerciciosConSesiones.filter { par in
            // Asumimos que EjercicioPostContenido tiene una propiedad `categoria` de tipo String.
            // Si no existiera, reemplace el acceso a la propiedad con la correcta.
            return (par.ejercicio.categoria == categoriaSeleccionada)
        }
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
                    categoriasDisponibles = ["Todas"]
                    categoriaSeleccionada = "Todas"
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
                // Construir categorías disponibles a partir de los ejercicios cargados
                let cats = Set(ejerciciosConSesiones.compactMap { $0.ejercicio.categoria })
                let ordenadas = ["Todas"] + cats.sorted()
                categoriasDisponibles = ordenadas
                if !ordenadas.contains(categoriaSeleccionada) {
                    categoriaSeleccionada = "Todas"
                }
                cargando = false
            }
        } catch {
            print("❌ Error al cargar estadísticas: \(error)")
            await MainActor.run { cargando = false }
        }
    }
}
