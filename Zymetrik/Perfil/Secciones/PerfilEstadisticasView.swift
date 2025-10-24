import SwiftUI

struct PerfilEstadisticasView: View {
    /// Si nil => estadísticas del usuario autenticado. Si no, del perfil indicado.
    let perfilId: UUID?

    @EnvironmentObject private var statsStore: StatsStore

    @State private var ejerciciosConSesiones: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] = []
    @State private var ejerciciosAbiertos: Set<UUID> = []
    @State private var categoriaSeleccionada: String = "Todas"
    @State private var categoriasDisponibles: [String] = ["Todas"]
    @State private var hasLoaded: Bool = false

    var body: some View {
        ScrollView {
            // Filtro por categoría
            if hasLoaded {
                VStack(alignment: .leading, spacing: 10) {
                    Menu {
                        // Opción "Todas"
                        Button(action: { categoriaSeleccionada = "Todas" }) {
                            HStack {
                                Text("Todas")
                                Spacer()
                                if categoriaSeleccionada == "Todas" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Divider()
                        ForEach(categoriasDisponibles.filter { $0 != "Todas" }.sorted(), id: \.self) { cat in
                            Button(action: { categoriaSeleccionada = cat }) {
                                HStack {
                                    Text(cat)
                                    Spacer()
                                    if categoriaSeleccionada == cat {
                                        Image(systemName: "checkmark")
                                    }
                                }
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

            LazyVStack(spacing: 16) {
                if hasLoaded && ejerciciosConSesiones.isEmpty {
                    Text("No hay ejercicios con datos.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(ejerciciosOrdenados(), id: \.ejercicio.id) { par in
                        EstadisticaEjercicioCard(
                            ejercicio: par.ejercicio,
                            perfilId: perfilId,
                            ejerciciosAbiertos: $ejerciciosAbiertos
                        )
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task { await prefillAndRefresh() }
        .refreshable { await hardRefresh() }
    }

    // MARK: - Orden y filtros

    private func ejerciciosOrdenados() -> [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])] {
        let base: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])]
        if categoriaSeleccionada == "Todas" {
            base = ejerciciosConSesiones
        } else {
            base = ejerciciosConSesiones.filter { $0.ejercicio.categoria == categoriaSeleccionada }
        }

        // Orden alfabético por nombre (localizado y case-insensitive)
        return base.sorted {
            $0.ejercicio.nombre.localizedCaseInsensitiveCompare($1.ejercicio.nombre) == .orderedAscending
        }
    }

    // MARK: - Carga instantánea + refresco silencioso

    private func prefillAndRefresh() async {
        let target: UUID? = perfilId ?? SupabaseManager.shared.client.auth.currentSession?.user.id
        guard let authorId = target else { return }

        // 1) Prefill instantáneo desde store si existe
        let pref = statsStore.stats(for: authorId)
        if !pref.isEmpty {
            await MainActor.run {
                ejerciciosConSesiones = pref
                applyCategories()
                hasLoaded = true
            }
        }

        // 2) Reload silencioso
        await statsStore.reload(authorId: authorId)

        // 3) Volcar resultado actualizado
        let updated = statsStore.stats(for: authorId)
        await MainActor.run {
            ejerciciosConSesiones = updated
            applyCategories()
            hasLoaded = true
        }
    }

    private func hardRefresh() async {
        let target: UUID? = perfilId ?? SupabaseManager.shared.client.auth.currentSession?.user.id
        guard let authorId = target else { return }
        await statsStore.reload(authorId: authorId)
        let updated = statsStore.stats(for: authorId)
        await MainActor.run {
            ejerciciosConSesiones = updated
            applyCategories()
            hasLoaded = true
        }
    }

    private func applyCategories() {
        let cats = Set(ejerciciosConSesiones.compactMap { $0.ejercicio.categoria })
        let ordenadas = ["Todas"] + cats.sorted()
        categoriasDisponibles = ordenadas
        if !ordenadas.contains(categoriaSeleccionada) {
            categoriaSeleccionada = "Todas"
        }
    }
}
