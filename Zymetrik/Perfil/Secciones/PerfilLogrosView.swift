import SwiftUI
import Supabase

struct PerfilLogrosView: View {
    /// Si nil => los del usuario autenticado. Si no, los del perfil indicado.
    let perfilId: UUID?

    @State private var logrosCompletados: [LogroConEstado] = []
    @State private var logrosPendientes:  [LogroConEstado] = []
    @State private var cargando = true

    @State private var logroDesbloqueado: LogroConEstado?
    @State private var mostrarLogro = false

    @State private var esMismoUsuario = false
    @State private var targetId: UUID?

    init(perfilId: UUID? = nil) {
        self.perfilId = perfilId
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if cargando {
                        ProgressView("Cargando logros…")
                            .padding(.vertical, 24)
                    } else if logrosCompletados.isEmpty && logrosPendientes.isEmpty {
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
                .padding(.vertical, 12) // sin padding horizontal → full-bleed
            }
            .background(Color(.systemBackground).ignoresSafeArea())

            // Overlay solo cuando es el propio usuario
            if esMismoUsuario, mostrarLogro, let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) {
                    withAnimation { mostrarLogro = false }
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
        .task {
            await resolverTarget()
            await cargarLogros(borderlessAward: true)
        }
        .refreshable { await cargarLogros(borderlessAward: false) }
    }

    // MARK: - Resolución de target (self u otro)
    private func resolverTarget() async {
        do {
            let me = try await SupabaseService.shared.client.auth.session.user.id
            if let perfilId {
                targetId = perfilId
                esMismoUsuario = (perfilId == me)
            } else {
                targetId = me
                esMismoUsuario = true
            }
        } catch {
            // Si falla la sesión, por seguridad no ejecutamos award
            targetId = perfilId
            esMismoUsuario = false
        }
    }

    // MARK: - Carga + award opcional si es el propio usuario
    @MainActor
    private func setLists(_ all: [LogroConEstado]) {
        logrosCompletados = all.filter { $0.desbloqueado }
        logrosPendientes  = all.filter { !$0.desbloqueado }
        cargando = false
    }

    private func cargarLogros(borderlessAward: Bool) async {
        guard let targetId else { return }
        cargando = true
        do {
            let all: [LogroConEstado]
            if esMismoUsuario {
                // 1) Carga estado actual
                let actuales = try await SupabaseService.shared.fetchLogrosCompletos()

                // 2) Award solo si procede
                if borderlessAward {
                    let nuevos = await SupabaseService.shared.awardAchievementsRPC()
                    if !nuevos.isEmpty {
                        // 3) Refresca y muestra overlay del primero
                        let refreshed = try await SupabaseService.shared.fetchLogrosCompletos()
                        await MainActor.run {
                            setLists(refreshed)
                            if let primero = nuevos.first,
                               let modelo = refreshed.first(where: { $0.id == primero }) {
                                logroDesbloqueado = modelo
                                withAnimation(.spring()) { mostrarLogro = true }
                            } else {
                                mostrarLogro = false
                            }
                        }
                        return
                    }
                }

                all = actuales
            } else {
                // Otro usuario → no ejecutar award, solo leer
                all = try await SupabaseService.shared.fetchLogrosCompletos(autorId: targetId)
                await MainActor.run { mostrarLogro = false }
            }

            await MainActor.run { setLists(all) }
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
                .padding(.horizontal, 16) // pequeño margen del título

            ForEach(logros) { logro in
                LogroCardView(logro: logro)
            }
        }
    }
}
