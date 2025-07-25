import SwiftUI

struct PerfilLogrosView: View {
    @State private var logrosCompletados: [LogroConEstado] = []
    @State private var logrosPendientes: [LogroConEstado] = []
    @State private var cargando = true
    @State private var logroDesbloqueado: LogroConEstado?
    @State private var mostrarLogro = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if cargando {
                    ProgressView("Cargando logros...")
                        .padding(.top)
                } else if logrosCompletados.isEmpty && logrosPendientes.isEmpty {
                    Text("No tienes logros aún.")
                        .foregroundColor(.gray)
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
        .background(Color.white.ignoresSafeArea())
        .task {
            await cargarLogros()
        }
    }

    func cargarLogros() async {
        do {
            let logros = try await SupabaseService.shared.fetchLogrosCompletos()

            await MainActor.run {
                logrosCompletados = logros.filter { $0.desbloqueado }
                logrosPendientes = logros.filter { !$0.desbloqueado }
                cargando = false
            }
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
