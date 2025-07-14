import SwiftUI

struct ListaEjerciciosView: View {
    let fecha: Date
    var onGuardar: ([Ejercicio]) -> Void
    @Binding var isPresented: Bool

    @State private var ejercicios: [Ejercicio] = []
    @State private var tipoSeleccionado: String = "Gimnasio"
    @State private var seleccionados: Set<UUID> = []

    private let tipos = ["Gimnasio", "Cardio", "Funcional"]
    @Namespace private var tipoAnimacion

    var ejerciciosFiltradosPorTipo: [String: [Ejercicio]] {
        Dictionary(grouping: ejercicios.filter { $0.tipo == tipoSeleccionado }) { $0.categoria }
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
                    EjerciciosAgrupadosView(
                        ejerciciosFiltradosPorTipo: ejerciciosFiltradosPorTipo,
                        tipoSeleccionado: tipoSeleccionado,
                        seleccionados: $seleccionados
                    )
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Seleccionar ejercicios")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let elegidos = ejercicios.filter { seleccionados.contains($0.id) }
                        guard !elegidos.isEmpty else {
                            print("⚠️ Nada seleccionado")
                            return
                        }

                        onGuardar(elegidos)
                        isPresented = false
                    } label: {
                        Text("añadir")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                fetchEjercicios()
            }
        }
    }

    func fetchEjercicios() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id

                async let allEjercicios: [Ejercicio] = SupabaseManager.shared.client
                    .from("ejercicios")
                    .select()
                    .execute()
                    .decodedList(to: Ejercicio.self)

                async let favoritos: [FavoritoID] = SupabaseManager.shared.client
                    .from("ejercicios_favoritos")
                    .select("ejercicio_id")
                    .eq("autor_id", value: userId)
                    .execute()
                    .decodedList(to: FavoritoID.self)

                let (todos, favoritosIDs) = try await (allEjercicios, favoritos)
                let favs = favoritosIDs.map(\.ejercicio_id)

                ejercicios = todos.map { ejercicio in
                    var copy = ejercicio
                    copy.esFavorito = favs.contains(ejercicio.id)
                    return copy
                }

            } catch {
                print("❌ Error al cargar ejercicios o favoritos:", error)
            }
        }
    }

    struct FavoritoID: Decodable {
        let ejercicio_id: UUID
    }
}
