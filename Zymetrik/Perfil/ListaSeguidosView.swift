import SwiftUI

struct ListaSeguidosView: View {
    @State private var searchText = ""

    let seguidos = ["gymbro", "entrena_con_lu", "ztrainer", "carlafit", "powerjuan"]

    var seguidosFiltrados: [String] {
        searchText.isEmpty ? seguidos : seguidos.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔍 Barra de búsqueda mejorada
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Buscar seguidos", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)

                // 📋 Lista de seguidos
                List(seguidosFiltrados, id: \.self) { usuario in
                    NavigationLink(destination: UserProfileView(username: usuario)) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(usuario)
                                    .font(.headline)
                                Text("Ver perfil")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: {}) {
                                Text("Siguiendo")
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                            }
                            .background(Color(.systemGray5))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Seguidos")
        }
    }
}
