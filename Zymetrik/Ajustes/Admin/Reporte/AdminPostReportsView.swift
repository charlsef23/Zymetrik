import SwiftUI
import Supabase

// MARK: - Modelos

struct PostReport: Identifiable, Decodable {
    let id: UUID
    let post_id: UUID
    let reporter_id: UUID?
    let reporter_username: String?
    let reason: String?
    let status: String // "open" | "resolved" | "dismissed"
    let created_at: Date
    let post_excerpt: String?
    let post_username: String?
}

enum PostReportStatus: String, CaseIterable, Identifiable {
    case all = "Todos"
    case open = "Abiertos"
    case resolved = "Resueltos"
    case dismissed = "Descartados"

    var id: String { rawValue }

    var backendValue: String? {
        switch self {
        case .all: return nil
        case .open: return "open"
        case .resolved: return "resolved"
        case .dismissed: return "dismissed"
        }
    }

    var tint: Color {
        switch self {
        case .all: return .secondary
        case .open: return .orange
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }
}

// MARK: - Servicio

final class AdminPostReportsService {
    static let shared = AdminPostReportsService()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    private let reportsSource = "post_reports"
    private let reportsEnriched = "post_reports_enriched"

    func fetchReports(status: String?, search: String, limit: Int = 200) async throws -> [PostReport] {
        // ---------- Intento con vista enriquecida ----------
        do {
            let pattern = "%\(search)%"

            var tq = client
                .from(reportsEnriched)
                .select("id, post_id, reporter_id, reporter_username, reason, status, created_at, post_excerpt, post_username")

            if let status {
                tq = tq.filter("status", operator: "eq", value: status)
            }
            if !search.isEmpty {
                tq = tq.filter("reason", operator: "ilike", value: pattern)
            }

            let res = try await tq
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            return try JSONDecoder.iso8601.decode([PostReport].self, from: res.data)
        } catch {
            // ---------- Fallback a tabla básica ----------
            let pattern = "%\(search)%"

            var tq = client
                .from(reportsSource)
                .select("id, post_id, reporter_id, reason, status, created_at")

            if let status {
                tq = tq.filter("status", operator: "eq", value: status)
            }
            if !search.isEmpty {
                tq = tq.filter("reason", operator: "ilike", value: pattern)
            }

            let res = try await tq
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            struct Basic: Decodable {
                let id: UUID
                let post_id: UUID
                let reporter_id: UUID?
                let reason: String?
                let status: String
                let created_at: Date
            }

            let basics = try JSONDecoder.iso8601.decode([Basic].self, from: res.data)
            return basics.map {
                PostReport(
                    id: $0.id,
                    post_id: $0.post_id,
                    reporter_id: $0.reporter_id,
                    reporter_username: nil,
                    reason: $0.reason,
                    status: $0.status,
                    created_at: $0.created_at,
                    post_excerpt: nil,
                    post_username: nil
                )
            }
        }
    }

    func updateReportStatus(reportID: UUID, newStatus: String) async throws {
        _ = try await client
            .from(reportsSource)
            .update(["status": newStatus])
            .filter("id", operator: "eq", value: reportID.uuidString)
            .execute()
    }
}

// MARK: - Helpers de decodificación

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = f.date(from: s) { return date }
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let date = f2.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid ISO8601 date: \(s)")
        }
        return d
    }
}

// MARK: - Vista principal

struct AdminPostReportsView: View {
    @State private var searchText = ""
    @State private var status: PostReportStatus = .open
    @State private var reports: [PostReport] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var selectedReport: PostReport?

    // Debounce
    @State private var searchDebounce: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 12) {
            // Filtros
            Picker("", selection: $status) {
                ForEach(PostReportStatus.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)

            // Buscar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Buscar por usuario/motivo…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Borrar búsqueda")
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Contenido
            Group {
                if loading {
                    VStack(spacing: 10) {
                        ProgressView("Cargando reportes…")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                } else if let errorText {
                    VStack(spacing: 10) {
                        Text("No se pudieron cargar los reportes.")
                            .font(.headline)
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Reintentar") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 24)
                } else if reports.isEmpty {
                    ContentVacioView(
                        title: "Sin reportes",
                        subtitle: "No hay reportes para mostrar con los filtros actuales."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 24)
                } else {
                    List {
                        ForEach(reports) { r in
                            Button { selectedReport = r } label: {
                                ReportRow(report: r)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollDismissesKeyboard(.interactively)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // <- clave para ocupar todo
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // <- clave
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reportes de posts")
        .task { await load() }
        .onChange(of: status) { _, _ in
            Task { await load() }
        }
        .onChange(of: searchText) { _, _ in
            searchDebounce?.cancel()
            let work = DispatchWorkItem { Task { await load() } }
            searchDebounce = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
        }
        .sheet(item: $selectedReport) { r in
            AdminPostReportDetailView(report: r) {
                Task { await load() }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func load() async {
        await MainActor.run {
            loading = true
            errorText = nil
        }
        do {
            let arr = try await AdminPostReportsService.shared.fetchReports(
                status: status.backendValue,
                search: searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                self.reports = arr
                self.loading = false
            }
        } catch {
            await MainActor.run {
                self.errorText = error.localizedDescription
                self.reports = []
                self.loading = false
            }
        }
    }
}

// MARK: - Row

private struct ReportRow: View {
    let report: PostReport

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Badge de estado
            Text(badgeText)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.15))
                .foregroundStyle(badgeColor)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("@\(report.post_username ?? "desconocido")")
                        .font(.subheadline.weight(.semibold))
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(report.created_at.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let reason = report.reason, !reason.isEmpty {
                    Text(reason).foregroundStyle(.primary)
                        .lineLimit(2)
                } else {
                    Text("Sin motivo").foregroundStyle(.secondary)
                }

                if let excerpt = report.post_excerpt, !excerpt.isEmpty {
                    Text("“\(excerpt)”")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let ru = report.reporter_username {
                    Text("Reportado por @\(ru)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private var badgeText: String {
        switch report.status {
        case "open": return "Abierto"
        case "resolved": return "Resuelto"
        case "dismissed": return "Descartado"
        default: return report.status.capitalized
        }
    }

    private var badgeColor: Color {
        switch report.status {
        case "open": return .orange
        case "resolved": return .green
        case "dismissed": return .gray
        default: return .secondary
        }
    }
}

// MARK: - Detalle con acciones

struct AdminPostReportDetailView: View {
    let report: PostReport
    var onUpdated: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var working = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    section(title: "Motivo") {
                        Text(report.reason?.isEmpty == false ? report.reason! : "—")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    section(title: "Post") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("@\(report.post_username ?? "desconocido")")
                                .font(.subheadline.weight(.semibold))
                            Text(report.post_excerpt?.isEmpty == false ? report.post_excerpt! : "Sin extracto")
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    section(title: "Estado") {
                        Text(statusText(report.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(report.status).opacity(0.15))
                            .foregroundStyle(statusColor(report.status))
                            .clipShape(Capsule())
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task { await updateStatus("resolved") }
                        } label: {
                            actionLabel("Marcar como resuelto", systemImage: "checkmark.seal.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)

                        Button {
                            Task { await updateStatus("dismissed") }
                        } label: {
                            actionLabel("Descartar reporte", systemImage: "slash.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(working)

                        Divider().padding(.vertical, 4)

                        Button(role: .destructive) {
                            Task { await eliminarPost() }
                        } label: {
                            actionLabel("Eliminar post", systemImage: "trash.fill")
                        }
                        .disabled(working)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Reporte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ID reporte: \(report.id.uuidString)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(report.created_at.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionLabel(_ text: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(text).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusText(_ s: String) -> String {
        switch s {
        case "open": return "Abierto"
        case "resolved": return "Resuelto"
        case "dismissed": return "Descartado"
        default: return s.capitalized
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "open": return .orange
        case "resolved": return .green
        case "dismissed": return .gray
        default: return .secondary
        }
    }

    // Acciones
    private func updateStatus(_ newStatus: String) async {
        guard !working else { return }
        await MainActor.run {
            working = true
            errorText = nil
        }
        do {
            try await AdminPostReportsService.shared.updateReportStatus(reportID: report.id, newStatus: newStatus)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await MainActor.run {
                working = false
                onUpdated()
                dismiss()
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            await MainActor.run {
                errorText = error.localizedDescription
                working = false
            }
        }
    }

    private func eliminarPost() async {
        guard !working else { return }
        await MainActor.run {
            working = true
            errorText = nil
        }
        do {
            try await SupabaseService.shared.eliminarPost(postID: report.post_id)
            // Opcional: también resolvemos el reporte
            try? await AdminPostReportsService.shared.updateReportStatus(reportID: report.id, newStatus: "resolved")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await MainActor.run {
                working = false
                onUpdated()
                dismiss()
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            await MainActor.run {
                errorText = "No se pudo eliminar el post: \(error.localizedDescription)"
                working = false
            }
        }
    }
}
