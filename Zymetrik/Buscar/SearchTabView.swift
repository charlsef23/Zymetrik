import SwiftUI

struct SearchTabView: View {
    // Estado interno del tab de búsqueda
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false

    var body: some View {
        NavigationStack {
            // Tu vista de búsqueda existente
            BuscarView(
                searchText: $searchText,
                isSearchActive: $isSearchActive
            )
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
