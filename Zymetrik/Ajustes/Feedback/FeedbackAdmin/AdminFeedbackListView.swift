import SwiftUI

struct AdminFeedbackListView: View {
    @State private var items: [FeedbackRecord] = []
    @State private var loading = false
    @State private var errorText: String?

    // Filtros
    @State private var filtroTipo: String = "todos"
    @State private var filtroEstado: String = "todos"
    @State private var filtroSeveridad: String = "todas"
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filtros
                List {
                    ForEach(items) { fb in
                        NavigationLink {
                            AdminFeedbackDetailView(record: fb) { newState in
                                // Refresca estado en la lista
                                if let idx = items.firstIndex(where: { $0.id == fb.id }) {
                                    items[idx] = FeedbackRecord(
                                        id: fb.id,
                                        autor_id: fb.autor_id,
                                        creado_en: fb.creado_en,
                                        tipo: fb.tipo,
                                        titulo: fb.titulo,
                                        mensaje: fb.mensaje,
                                        categoria: fb.categoria,
                                        severidad: fb.severidad,
                                        calificacion: fb.calificacion,
                                        email_contacto: fb.email_contacto,
                                        app_version: fb.app_version,
                                        os_version: fb.os_version,
                                        device_model: fb.device_model,
                                        screenshot_path: fb.screenshot_path,
                                        estado: newState
                                    )
                                }
                            }
                        } label: {
                            row(fb)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Feedback (Admin)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await cargar() }
                    } label: {
                        if loading { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                    }
                    .disabled(loading)
                }
            }
            .onAppear { Task { await cargar() } }
            .alert("Error", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Buscar en título o mensaje")
        .onChange(of: searchText) { _, _ in
            Task { await cargar() }
        }
    }

    private var filtros: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Menu {
                    Picker("Tipo", selection: $filtroTipo) {
                        Text("Todos").tag("todos")
                        Text("Bug").tag("bug")
                        Text("Idea").tag("idea")
                        Text("UI").tag("ui")
                        Text("Otro").tag("otro")
                    }
                } label: {
                    chipLabel(text: "Tipo: \(filtroTipo.capitalized)")
                }
                .onChange(of: filtroTipo) { _, _ in
                    Task { await cargar() }
                }

                Menu {
                    Picker("Estado", selection: $filtroEstado) {
                        Text("Todos").tag("todos")
                        Text("Nuevo").tag("nuevo")
                        Text("Revisado").tag("revisado")
                        Text("Resuelto").tag("resuelto")
                    }
                } label: {
                    chipLabel(text: "Estado: \(filtroEstado.capitalized)")
                }
                .onChange(of: filtroEstado) { _, _ in
                    Task { await cargar() }
                }

                Menu {
                    Picker("Severidad", selection: $filtroSeveridad) {
                        Text("Todas").tag("todas")
                        Text("Baja").tag("baja")
                        Text("Media").tag("media")
                        Text("Alta").tag("alta")
                        Text("Crítica").tag("critica")
                    }
                } label: {
                    chipLabel(text: "Severidad: \(filtroSeveridad.capitalized)")
                }
                .onChange(of: filtroSeveridad) { _, _ in
                    Task { await cargar() }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func chipLabel(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }

    private func row(_ fb: FeedbackRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(fb.titulo).font(.headline)
                Spacer()
                estadoChip(fb.estado)
            }
            HStack(spacing: 8) {
                label(system: "tag", fb.tipo.capitalized)
                if let sev = fb.severidad { label(system: "exclamationmark.triangle", sev.capitalized) }
                if let cat = fb.categoria, !cat.isEmpty { label(system: "square.grid.2x2", cat) }
            }
            .foregroundStyle(.secondary)
            Text(fb.mensaje)
                .lineLimit(2)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            HStack {
                Text(fb.device_model ?? "—")
                Text("•")
                Text(fb.os_version ?? "—")
                if let v = fb.app_version { Text("• v\(v)") }
                Spacer()
                Text(fb.creado_en.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }

    private func label(system: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: system)
            Text(text)
        }
        .font(.caption)
    }

    private func estadoChip(_ estado: String) -> some View {
        let color: Color = {
            switch estado {
            case "nuevo": return .blue
            case "revisado": return .orange
            case "resuelto": return .green
            default: return .gray
            }
        }()
        return Text(estado.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.15)))
    }

    @MainActor
    private func cargar() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let tipo = (filtroTipo == "todos") ? nil : filtroTipo
            let estado = (filtroEstado == "todos") ? nil : filtroEstado
            let sev = (filtroSeveridad == "todas") ? nil : filtroSeveridad
            let data = try await FeedbackAdminService.shared.fetchFeedbacks(
                tipo: tipo,
                estado: estado,
                severidad: sev,
                search: searchText.isEmpty ? nil : searchText,
                limit: 100
            )
            items = data
        } catch {
            errorText = error.localizedDescription
        }
    }
}
