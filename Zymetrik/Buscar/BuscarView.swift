import SwiftUI
import Supabase

struct BuscarView: View {
    @State private var searchText = ""
    @State private var resultados: [Perfil] = []
    @State private var seguidos: Set<UUID> = []
    @State private var cargando = false
    @State private var userID: UUID? = nil
    @FocusState private var searchFocused: Bool

    @State private var perfilSeleccionado: Perfil?
    @State private var navegar = false

    @State private var historial: [Perfil] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                barraBusqueda

                if !historial.isEmpty && searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(historial, id: \.id) { perfil in
                                Button {
                                    perfilSeleccionado = perfil
                                    navegar = true
                                } label: {
                                    HStack(spacing: 6) {
                                        if let url = perfil.avatar_url, let imageURL = URL(string: url) {
                                            AsyncImage(url: imageURL) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 28, height: 28)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .frame(width: 28, height: 28)
                                                .foregroundColor(.gray)
                                        }

                                        Text(perfil.username)
                                            .font(.caption)
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    Button("Eliminar historial") {
                        Task { await eliminarHistorialDesdeSupabase() }
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                ScrollView {
                    if cargando {
                        ProgressView().padding(.top, 32)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(resultados) { perfil in
                                Button {
                                    perfilSeleccionado = perfil
                                    navegar = true
                                    Task { await guardarHistorialEnSupabase(perfil: perfil) }
                                } label: {
                                    UsuarioRowView(perfil: perfil, seguidos: $seguidos, currentUserID: userID)
                                }
                                .buttonStyle(.plain)

                                Divider().padding(.leading, 72)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Buscar")
            .navigationDestination(isPresented: $navegar) {
                destinoVistaPerfil()
            }
            .task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.session
                    self.userID = session.user.id
                    await cargarHistorialDesdeSupabase()
                } catch {
                    print("❌ Error al obtener sesión:", error)
                }
            }
        }
    }

    @ViewBuilder
    func destinoVistaPerfil() -> some View {
        if let seleccionado = perfilSeleccionado {
            if seleccionado.id == userID {
                PerfilView()
            } else {
                UserProfileView(username: seleccionado.username)
            }
        } else {
            EmptyView()
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

            let session = try await SupabaseManager.shared.client.auth.session
            let currentUserID = session.user.id

            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id, username, nombre, avatar_url")
                .ilike("username", pattern: "%\(searchText)%")
                .order("username")
                .limit(20)
                .execute()

            resultados = try response.decodedList(to: Perfil.self)

            // Cargar seguidos
            let seguidoresResponse = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id")
                .eq("follower_id", value: currentUserID.uuidString)
                .execute()

            if let jsonArray = try? JSONSerialization.jsonObject(with: seguidoresResponse.data) as? [[String: String]] {
                let ids = jsonArray.compactMap { $0["followed_id"] }.compactMap { UUID(uuidString: $0) }
                seguidos = Set(ids)
            }

        } catch {
            print("❌ Error al buscar usuarios:", error)
        }

        cargando = false
    }

    func cargarHistorialDesdeSupabase() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString

            let response = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .select("perfil:perfil_id(id, username, nombre, avatar_url)")
                .eq("usuario_id", value: userID)
                .order("buscado_en", ascending: false)
                .limit(10)
                .execute()

            if let resultados = try? response.decoded(to: [[String: Perfil]].self) {
                historial = resultados.compactMap { $0["perfil"] }
            }

        } catch {
            print("❌ Error al cargar historial:", error)
        }
    }

    struct NuevoHistorial: Encodable {
        let usuario_id: String
        let perfil_id: String
    }

    func guardarHistorialEnSupabase(perfil: Perfil) async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        let userID = session.user.id.uuidString

        let nuevo = NuevoHistorial(usuario_id: userID, perfil_id: perfil.id.uuidString)

        do {
            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .insert(nuevo)
                .execute()
        } catch {
            print("❌ Error al guardar historial:", error)
        }
    }


    func eliminarHistorialDesdeSupabase() async {
        guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
        let userID = session.user.id.uuidString

        do {
            _ = try await SupabaseManager.shared.client
                .from("historial_busqueda")
                .delete()
                .eq("usuario_id", value: userID)
                .execute()

            historial = []
        } catch {
            print("❌ Error al eliminar historial:", error)
        }
    }
}
