//
//  FavoritosEntrenamientosView.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//

import SwiftUI
import SwiftData

struct FavoritosEntrenamientosView: View {
    @Environment(\.modelContext) private var context
    @Query private var favoritos: [FavoriteWorkoutTitle]

    @State private var favoritoAEliminar: FavoriteWorkoutTitle?
    @State private var mostrarAlertaEliminar = false

    var onSeleccionar: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(favoritos.sorted(by: { $0.createdAt > $1.createdAt })) { fav in
                    HStack {
                        Text(fav.title)
                        Spacer()
                        Button {
                            onSeleccionar?(fav.title)
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

                if favoritos.isEmpty {
                    Text("No hay entrenamientos favoritos.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Entrenamientos favoritos")
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
