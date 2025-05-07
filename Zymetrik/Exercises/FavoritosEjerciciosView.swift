import SwiftUI
import SwiftData

struct FavoritosEjerciciosView: View {
    @Environment(\.modelContext) private var context
    @Query private var favoritos: [FavoriteExercise]

    @State private var favoritoAEliminar: FavoriteExercise?
    @State private var mostrarAlertaEliminar = false

    var onSeleccionar: ((FavoriteExercise) -> Void)?

    var favoritosPorCategoria: [String: [FavoriteExercise]] {
        Dictionary(grouping: favoritos) { $0.category }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(favoritosPorCategoria.sorted(by: { $0.key < $1.key }), id: \.key) { categoria, ejercicios in
                    Section(header: Text(categoria)) {
                        ForEach(ejercicios.sorted(by: { $0.createdAt > $1.createdAt })) { fav in
                            HStack {
                                Text(fav.name)
                                Spacer()
                                Button {
                                    onSeleccionar?(fav) // ← Aquí se pasa de vuelta el seleccionado
                                } label: {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Button {
                                    favoritoAEliminar = fav
                                    mostrarAlertaEliminar = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                if favoritos.isEmpty {
                    Text("No hay ejercicios favoritos.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Favoritos por categoría")
            .alert("¿Eliminar favorito?", isPresented: $mostrarAlertaEliminar, actions: {
                Button("Eliminar", role: .destructive) {
                    if let fav = favoritoAEliminar {
                        context.delete(fav)
                        try? context.save()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }, message: {
                Text("Esta acción no se puede deshacer.")
            })
        }
    }
}
