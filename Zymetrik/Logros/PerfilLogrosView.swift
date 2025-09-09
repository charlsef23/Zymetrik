import SwiftUI

struct PerfilLogrosView: View {
    @State private var logrosCompletados: [LogroConEstado] = []
    @State private var logrosPendientes: [LogroConEstado] = []
    @State private var cargando = true

    @State private var logroDesbloqueado: LogroConEstado?
    @State private var mostrarLogro = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if cargando {
                        ProgressView("Cargando logros...")
                            .padding(.top)
                    } else if logrosCompletados.isEmpty && logrosPendientes.isEmpty {
                        Text("No tienes logros aún.")
                            .foregroundColor(.gray)
                            .padding(.top, 24)
                    } else {
                        if !logrosCompletados.isEmpty {
                            SectionView(titulo: "Completados", logros: logrosCompletados)
                        }

                        if !logrosPendientes.isEmpty {
                            SectionView(titulo: "Pendientes", logros: logrosPendientes)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).ignoresSafeArea())

            if mostrarLogro, let logro = logroDesbloqueado {
                LogroDesbloqueadoView(logro: logro) {
                    withAnimation {
                        mostrarLogro = false
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
        .task {
            // 1) Cargar estado actual
            await cargarLogros()

            // 2) Analizar logros y obtener nuevos IDs
            let nuevos = await SupabaseService.shared.analizarYDesbloquearLogros()

            // 3) Si hay nuevos, refrescar lista y mostrar alerta del primero
            if !nuevos.isEmpty {
                await cargarLogros()
                if let primero = nuevos.first,
                   let modelo = (logrosCompletados.first { $0.id == primero }) {
                    await MainActor.run {
                        logroDesbloqueado = modelo
                        withAnimation(.spring()) {
                            mostrarLogro = true
                        }
                    }
                }
            }
        }
        // Opcional: permite "pull to refresh"
        .refreshable {
            await cargarLogros()
        }
    }

    @MainActor
    func cargarLogros() async {
        do {
            let logros = try await SupabaseService.shared.fetchLogrosCompletos()
            logrosCompletados = logros.filter { $0.desbloqueado }
            logrosPendientes = logros.filter { !$0.desbloqueado }
            cargando = false
        } catch {
            print("❌ Error al cargar logros:", error)
            cargando = false
        }
    }
}

struct SectionView: View {
    let titulo: String
    let logros: [LogroConEstado]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            ForEach(logros) { logro in
                LogroCardView(logro: logro)
            }
        }
    }
}
