import SwiftUI
import Supabase

struct PerfilLogrosView: View {
    let perfilId: UUID?

    @State private var logrosCompletados: [LogroConEstado] = []
    @State private var logrosPendientes:  [LogroConEstado] = []
    @State private var cargando = true
    @State private var targetId: UUID?

    init(perfilId: UUID? = nil) { self.perfilId = perfilId }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if cargando {
                    ProgressView("Cargando logros…").padding(.vertical, 24)
                } else if logrosCompletados.isEmpty && logrosPendientes.isEmpty {
                    Text("No hay logros aún.").foregroundColor(.secondary).padding(.vertical, 24)
                } else {
                    if !logrosCompletados.isEmpty {
                        SectionView(titulo: "Completados", logros: logrosCompletados)
                    }
                    if !logrosPendientes.isEmpty {
                        SectionView(titulo: "Pendientes", logros: logrosPendientes)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task {
            await resolverTarget()
            await cargarLogros()
        }
        .refreshable {
            await cargarLogros()
        }
    }

    // MARK: - Resolver target (async por aislamiento de Supabase)
    private func resolverTarget() async {
        do {
            let session = try await SupabaseService.shared.client.auth.session
            let me = session.user.id
            targetId = perfilId ?? me
        } catch {
            targetId = perfilId
        }
    }

    // MARK: - Carga
    private func setLists(_ all: [LogroConEstado]) {
        logrosCompletados = all.filter { $0.desbloqueado }
        logrosPendientes  = all.filter { !$0.desbloqueado }
        cargando = false
    }

    private func cargarLogros() async {
        guard let targetId else {
            await MainActor.run { cargando = false }
            return
        }
        await MainActor.run { cargando = true }

        do {
            var me: UUID?
            if let session = try? await SupabaseService.shared.client.auth.session {
                me = session.user.id
            }

            let all: [LogroConEstado]
            if let me, me == targetId {
                all = try await SupabaseService.shared.fetchLogrosCompletos()
            } else {
                all = try await SupabaseService.shared.fetchLogrosCompletos(autorId: targetId)
            }

            await MainActor.run { setLists(all) }   // 👈 hop correcto
        } catch {
            print("❌ Error al cargar logros:", error)
            await MainActor.run { cargando = false }
        }
    }
}

// MARK: - Sección (sin bordes)
struct SectionView: View {
    let titulo: String
    let logros: [LogroConEstado]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)

            ForEach(logros) { logro in
                LogroCardModernView(logro: logro)
            }
        }
    }
}
