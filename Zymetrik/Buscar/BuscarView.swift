import SwiftUI
import Supabase

struct BuscarView: View {
    @State private var searchText = ""
    @State private var resultados: [Perfil] = []
    @State private var seguidos: Set<UUID> = []
    @State private var cargando = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                barraBusqueda

                ScrollViewReader { _ in
                    ScrollView {
                        if cargando {
                            ProgressView().padding(.top, 32)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(resultados) { perfil in
                                    NavigationLink(destination: UserProfileView(username: perfil.username)) {
                                        UsuarioRowView(perfil: perfil, seguidos: $seguidos)
                                    }
                                    .buttonStyle(.plain)

                                    Divider().padding(.leading, 72)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Buscar")
        }
    }

    var barraBusqueda: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Buscar usuarios", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($searchFocused)
                .onAppear { searchFocused = true }
                .onChange(of: searchText) {
                    Task { await buscarUsuarios() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    resultados = []
                } label: {
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
    }

    func buscarUsuarios() async {
        guard !searchText.isEmpty else {
            resultados = []
            return
        }

        do {
            cargando = true

            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, nombre, avatar_url")
                .ilike("username", pattern: "%\(searchText)%")
                .order("username")
                .limit(20)
                .execute()

            resultados = try response.decodedList(to: Perfil.self)
        } catch {
            print("❌ Error al buscar usuarios:", error)
        }

        cargando = false
    }
}
