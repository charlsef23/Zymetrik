import SwiftUI
import Supabase

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    @Binding var isPresented: Bool

    @State private var ejercicios: [Ejercicio] = []
    @State private var tipoSeleccionado: String = "Gimnasio"
    @State private var seleccionados: Set<UUID> = []
    @State private var cargando = false

    // ⬅️ Añadimos "Favoritos"
    private let tipos = ["Gimnasio", "Cardio", "Funcional", "Favoritos"]
    @Namespace private var tipoAnimacion

    // Agrupa por categoría con lógica especial para "Favoritos"
    var ejerciciosFiltradosPorTipo: [String: [Ejercicio]] {
        let base: [Ejercicio]
        if tipoSeleccionado == "Favoritos" {
            base = ejercicios.filter { $0.esFavorito }
        } else {
            base = ejercicios.filter { $0.tipo == tipoSeleccionado }
        }
        return Dictionary(grouping: base) { $0.categoria }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TipoSelectorView(
                        tipos: tipos,
                        tipoSeleccionado: $tipoSeleccionado,
                        tipoAnimacion: tipoAnimacion
                    )

                    if cargando {
                        ProgressView("Cargando ejercicios...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        EjerciciosAgrupadosView(
                            ejerciciosFiltradosPorTipo: ejerciciosFiltradosPorTipo,
                            tipoSeleccionado: tipoSeleccionado,
                            seleccionados: $seleccionados,
                            isFavorito: { id in
                                ejercicios.first(where: { $0.id == id })?.esFavorito ?? false
                            },
                            onToggleFavorito: { id in
                                toggleFavorito(ejercicioID: id)
                            }
                        )
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Seleccionar ejercicios")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let elegidos = ejercicios.filter { seleccionados.contains($0.id) }
                        guard !elegidos.isEmpty else { return }
                        onGuardar(elegidos)
                        isPresented = false
                    } label: {
                        Text("Añadir").fontWeight(.semibold)
                    }
                    .disabled(seleccionados.isEmpty)
                }
            }
            .onAppear {
                fetchEjercicios()
            }
        }
    }

    // MARK: - Data
    func fetchEjercicios() {
        Task {
            do {
                let items = try await SupabaseService.shared.fetchEjerciciosConFavoritos()
                await MainActor.run { self.ejercicios = items }
            } catch {
                print("❌ Error al cargar ejercicios:", error)
            }
        }
    }

    // MARK: - Helpers
    func toggleFavorito(ejercicioID: UUID) {
        guard let idx = ejercicios.firstIndex(where: { $0.id == ejercicioID }) else { return }
        ejercicios[idx].esFavorito.toggle()
        let target = ejercicios[idx].esFavorito
        Task {
            do {
                try await SupabaseService.shared.setFavorito(ejercicioID: ejercicioID, favorito: target)
            } catch {
                await MainActor.run { ejercicios[idx].esFavorito.toggle() }
                print("❌ Error al togglear favorito:", error)
            }
        }
    }
}
