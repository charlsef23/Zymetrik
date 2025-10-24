import SwiftUI
import Supabase

struct PerfilLogrosView: View {
    let perfilId: UUID?

    @EnvironmentObject private var achievementsStore: AchievementsStore

    @State private var logrosCompletados: [LogroConEstado] = []
    @State private var logrosPendientes:  [LogroConEstado] = []
    @State private var hasLoaded: Bool = false
    @State private var targetId: UUID?

    init(perfilId: UUID? = nil) { self.perfilId = perfilId }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if hasLoaded && logrosCompletados.isEmpty && logrosPendientes.isEmpty {
                    Text("No hay logros aún.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 24)
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
            await resolveTarget()
            await prefillAndRefresh()
        }
        .refreshable { await hardRefresh() }
    }

    // MARK: - Resolver target
    private func resolveTarget() async {
        if let perfilId {
            targetId = perfilId
        } else if let session = try? await SupabaseService.shared.client.auth.session {
            targetId = session.user.id
        }
    }

    // MARK: - Prefill + refresh
    private func prefillAndRefresh() async {
        guard let authorId = targetId else { return }

        // Prefill instantáneo
        let pref = achievementsStore.achievements(for: authorId)
        if !pref.isEmpty {
            await MainActor.run {
                setLists(pref)
                hasLoaded = true
            }
        }

        // Refresco silencioso
        await achievementsStore.reload(authorId: authorId)

        let updated = achievementsStore.achievements(for: authorId)
        await MainActor.run {
            setLists(updated)
            hasLoaded = true
        }
    }

    private func hardRefresh() async {
        guard let authorId = targetId else { return }
        await achievementsStore.reload(authorId: authorId)
        let updated = achievementsStore.achievements(for: authorId)
        await MainActor.run {
            setLists(updated)
            hasLoaded = true
        }
    }

    private func setLists(_ all: [LogroConEstado]) {
        logrosCompletados = all.filter { $0.desbloqueado }
        logrosPendientes  = all.filter { !$0.desbloqueado }
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
