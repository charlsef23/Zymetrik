import SwiftUI

struct ListaSeguidosView: View {
    @State private var searchText = ""

    let seguidosOriginales = ["gymbro", "entrena_con_lu", "ztrainer", "carlafit", "powerjuan"]

    @State private var seguidosVisibles: [String] = ["gymbro", "entrena_con_lu", "ztrainer", "carlafit", "powerjuan"]
    @State private var seguidos: Set<String> = ["gymbro", "entrena_con_lu", "ztrainer", "carlafit", "powerjuan"]
    @State private var temporizadores: [String: Timer] = [:]

    var seguidosFiltrados: [String] {
        searchText.isEmpty ? seguidosVisibles : seguidosVisibles.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔍 Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Buscar seguidos", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
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

                // 📋 Lista personalizada
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(seguidosFiltrados, id: \.self) { usuario in
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

                                    Button(action: {
                                        toggleSeguido(usuario)
                                    }) {
                                        Text(seguidos.contains(usuario) ? "Siguiendo" : "Seguir")
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(seguidos.contains(usuario) ? Color(.systemGray5) : Color.black)
                                            .foregroundColor(seguidos.contains(usuario) ? .black : .white)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
            }
            .navigationTitle("Seguidos")
        }
    }

    private func toggleSeguido(_ usuario: String) {
        if seguidos.contains(usuario) {
            // Se deja de seguir → mantener temporalmente
            seguidos.remove(usuario)

            // Si ya hay un temporizador, cancelarlo
            temporizadores[usuario]?.invalidate()

            // Crear uno nuevo para eliminar después de 3 segundos
            let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                if !seguidos.contains(usuario) {
                    seguidosVisibles.removeAll { $0 == usuario }
                }
                temporizadores.removeValue(forKey: usuario)
            }

            temporizadores[usuario] = timer

        } else {
            // Se vuelve a seguir antes de que desaparezca
            seguidos.insert(usuario)
            temporizadores[usuario]?.invalidate()
            temporizadores.removeValue(forKey: usuario)

            if !seguidosVisibles.contains(usuario) {
                seguidosVisibles.append(usuario)
            }
        }
    }
}
