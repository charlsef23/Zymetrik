import SwiftUI

struct AdminFeedbackDetailView: View {
    let record: FeedbackRecord
    var onEstadoChanged: (String) -> Void = { _ in }

    @State private var signedURL: URL?
    @State private var loadingImage = false
    @State private var mostrandoError = false
    @State private var errorText: String?

    @State private var estado: String

    init(record: FeedbackRecord, onEstadoChanged: @escaping (String) -> Void = { _ in }) {
        self.record = record
        self.onEstadoChanged = onEstadoChanged
        _estado = State(initialValue: record.estado)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(record.titulo)
                        .font(.title3).bold()
                    Spacer()
                    estadoPicker
                }

                etiquetas

                if let url = signedURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(maxWidth: .infinity)
                        case .success(let img):
                            img.resizable().scaledToFit().cornerRadius(12)
                        case .failure(_):
                            Text("No se pudo cargar la imagen")
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else if record.screenshot_path != nil {
                    if loadingImage {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Button {
                            Task { await cargarImagen() }
                        } label: {
                            Label("Ver captura adjunta", systemImage: "photo")
                        }
                    }
                }

                Group {
                    Text("Descripción").font(.headline)
                    Text(record.mensaje)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }

                Group {
                    Text("Dispositivo").font(.headline)
                    Text("\(record.device_model ?? "—") • \(record.os_version ?? "—")")
                        .foregroundStyle(.secondary)
                    if let v = record.app_version {
                        Text("App: v\(v)").foregroundStyle(.secondary)
                    }
                }

                if let email = record.email_contacto {
                    Button {
                        UIPasteboard.general.string = email
                    } label: {
                        Label("Copiar email de contacto", systemImage: "envelope")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Marcar como Nuevo") { Task { await cambiarEstado("nuevo") } }
                    Button("Marcar como Revisado") { Task { await cambiarEstado("revisado") } }
                    Button("Marcar como Resuelto") { Task { await cambiarEstado("resuelto") } }
                } label: {
                    Image(systemName: "checkmark.seal")
                }
            }
        }
        .alert("Error", isPresented: $mostrandoError) {
            Button("OK") { }
        } message: {
            Text(errorText ?? "")
        }
    }

    private var estadoPicker: some View {
        Text(estado.capitalized)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
    }

    private var etiquetas: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                chip("Tipo", record.tipo.capitalized, "tag")
                if let s = record.severidad { chip("Severidad", s.capitalized, "exclamationmark.triangle") }
                if let c = record.categoria, !c.isEmpty { chip("Categoría", c, "square.grid.2x2") }
            }
            Text(record.creado_en.formatted(date: .complete, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func chip(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text("\(title): \(value)")
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }

    @MainActor
    private func cargarImagen() async {
        guard let path = record.screenshot_path else { return }
        loadingImage = true
        defer { loadingImage = false }
        do {
            let url = try await FeedbackAdminService.shared.signedScreenshotURL(path: path)
            signedURL = url
        } catch {
            errorText = error.localizedDescription
            mostrandoError = true
        }
    }

    @MainActor
    private func cambiarEstado(_ nuevo: String) async {
        do {
            try await FeedbackAdminService.shared.actualizarEstado(id: record.id, nuevoEstado: nuevo)
            estado = nuevo
            onEstadoChanged(nuevo)
        } catch {
            errorText = "No se pudo actualizar el estado: \(error.localizedDescription)"
            mostrandoError = true
        }
    }
}
