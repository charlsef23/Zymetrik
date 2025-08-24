import SwiftUI
import Supabase

struct PerfilView: View {
    @State private var userID: String = ""
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var showAjustes = false
    @State private var showEditarPerfil = false

    @State private var nombre = "Cargando..."
    @State private var username = "..."
    @State private var presentacion = ""
    @State private var enlaces = ""
    @State private var imagenPerfilURL: String? = nil

    @State private var numeroDePosts: Int = 0
    @State private var seguidoresCount: Int = 0
    @State private var siguiendoCount: Int = 0

    let esVerificado = true

    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Fondo personalizado
                Color("Background1")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            HStack(spacing: 6) {
                                Text(username)
                                    .font(.title)
                                    .fontWeight(.bold)
                                if esVerificado {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.verificado)
                                        .font(.system(size: 20))
                                }
                            }
                            Spacer()
                            Button {
                                showAjustes = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal)

                        // Avatar + nombre + presentación
                        VStack(spacing: 12) {
                            if let urlString = imagenPerfilURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 84, height: 84)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .frame(width: 84, height: 84)
                                            .clipShape(Circle())
                                    case .failure:
                                        defaultAvatar
                                    @unknown default:
                                        defaultAvatar
                                    }
                                }
                            } else {
                                defaultAvatar
                            }

                            HStack(spacing: 6) {
                                Text(nombre)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                if esVerificado {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.verificado)
                                        .font(.system(size: 16))
                                }
                            }

                            Text(presentacion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            // Botones de acción
                            HStack {
                                Button {
                                    showEditarPerfil = true
                                } label: {
                                    Text("Editar perfil")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .background(Color.backgroundEditarPerfil)
                                        .foregroundColor(.foregroundEditarPerfil)
                                        .clipShape(Capsule())
                                }

                                NavigationLink(
                                    destination: ShareProfileView(username: username, profileImage: Image(systemName: "person"))
                                ) {
                                    Text("Compartir")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .background(Color.backgroundCompartir)
                                        .foregroundColor(.foregroundCompartir)
                                        .clipShape(Capsule())
                                }
                            }

                            // Contadores
                            HStack {
                                Spacer()
                                VStack {
                                    Text("\(numeroDePosts)").font(.headline).foregroundColor(.followNumber)
                                    Text("Entrenos").font(.caption).foregroundColor(.followNumber)
                                }
                                Spacer()
                                NavigationLink(destination: ListaSeguidoresView(userID: userID)) {
                                    VStack {
                                        Text("\(seguidoresCount)").font(.headline).foregroundColor(.followNumber)
                                        Text("Seguidores").font(.caption).foregroundColor(.followNumber)
                                    }
                                }
                                Spacer()
                                NavigationLink(destination: ListaSeguidosView(userID: userID)) {
                                    VStack {
                                        Text("\(siguiendoCount)").font(.headline).foregroundColor(.followNumber)
                                        Text("Siguiendo").font(.caption).foregroundColor(.followNumber)
                                    }
                                }
                                Spacer()
                            }
                        }

                        // Tabs
                        HStack {
                            ForEach(PerfilTab.allCases, id: \.self) { tab in
                                Button {
                                    selectedTab = tab
                                } label: {
                                    Text(tab.rawValue)
                                        .fontWeight(selectedTab == tab ? .bold : .regular)
                                        .foregroundColor(selectedTab == tab ? .black : .gray)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 16)
                                        .background(
                                            Capsule().fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Contenido por tab
                        if selectedTab == .entrenamientos {
                            PerfilEntrenamientosView(profileID: nil)
                        } else if selectedTab == .estadisticas {
                            PerfilEstadisticasView()
                        } else {
                            PerfilLogrosView()
                        }
                    }
                    .padding(.top)
                }
            }
            .sheet(isPresented: $showEditarPerfil) {
                EditarPerfilView(
                    nombre: $nombre,
                    username: $username,
                    presentacion: $presentacion,
                    enlaces: $enlaces,
                    imagenPerfilURL: $imagenPerfilURL
                )
            }
            .sheet(isPresented: $showAjustes) {
                SettingsView()
            }
            .task {
                await cargarDatosCompletos()
            }
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 84, height: 84)
            .clipShape(Circle())
            .foregroundColor(.gray)
    }

    // MARK: - Cargar datos iniciales
    func cargarDatosIniciales() async {
        do {
            _ = try await SupabaseManager.shared.client.auth.session
            await cargarPerfilDesdeSupabase()
        } catch {
            print("❌ Error al obtener sesión: \(error)")
        }
    }

    // MARK: - Cargar perfil desde Supabase
    func cargarPerfilDesdeSupabase() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString
            self.userID = userID

            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()

            let raw = response.data
            guard let json = try? JSONSerialization.jsonObject(with: raw, options: []) as? [String: Any] else {
                print("❌ No se pudo decodificar la respuesta")
                return
            }

            self.nombre = json["nombre"] as? String ?? ""
            self.username = json["username"] as? String ?? ""
            self.presentacion = json["presentacion"] as? String ?? ""
            self.enlaces = json["enlaces"] as? String ?? ""
            self.imagenPerfilURL = json["avatar_url"] as? String

        } catch {
            print("❌ Error al cargar perfil: \(error)")
        }
    }

    // MARK: - Cargar seguidores y siguiendo
    func cargarContadoresSeguidores() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString

            let seguidoresResponse = try await SupabaseManager.shared.client
                .from("followers")
                .select("follower_id", count: .exact)
                .eq("followed_id", value: userID)
                .execute()
            seguidoresCount = seguidoresResponse.count ?? 0

            let siguiendoResponse = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id", count: .exact)
                .eq("follower_id", value: userID)
                .execute()
            siguiendoCount = siguiendoResponse.count ?? 0

        } catch {
            print("❌ Error al cargar contadores: \(error)")
        }
    }

    // MARK: - Cargar número de posts
    func cargarNumeroDePosts() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userID = session.user.id.uuidString

            let response = try await SupabaseManager.shared.client
                .from("posts")
                .select("id", count: .exact)
                .eq("autor_id", value: userID)
                .execute()

            numeroDePosts = response.count ?? 0
        } catch {
            print("❌ Error al contar posts: \(error)")
        }
    }
    func cargarDatosCompletos() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await cargarDatosIniciales() }
            group.addTask { await cargarContadoresSeguidores() }
            group.addTask { await cargarNumeroDePosts() }
        }
    }
}
