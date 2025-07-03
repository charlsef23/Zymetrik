import SwiftUI
import Supabase

struct UserProfileView: View {
    let username: String
    
    @State private var nombre: String = ""
    @State private var avatarURL: String?
    @State private var presentacion: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var isFollowing = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    @State private var numeroDePosts = 0
    @State private var seguidoresCount = 0
    @State private var seguidosCount = 0
    @State private var profileUserID: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Foto y nombre
                VStack(spacing: 8) {
                    if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.gray)
                    }
                    
                    Text(nombre)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(presentacion.isEmpty ? "📍 Entrenando cada día\n💪 Fitness · Salud · Comunidad" : presentacion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Contadores
                HStack {
                    Spacer()
                    VStack {
                        Text("\(numeroDePosts)")
                            .font(.headline)
                        Text("Entrenos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    NavigationLink(destination: ListaSeguidoresView(userID: profileUserID)) {
                        VStack {
                            Text("\(seguidoresCount)")
                                .font(.headline)
                            Text("Seguidores")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    NavigationLink(destination: ListaSeguidosView(userID: profileUserID)) {
                        VStack {
                            Text("\(seguidosCount)")
                                .font(.headline)
                            Text("Siguiendo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                
                // Botón seguir
                Button(action: {
                    Task { await toggleFollow() }
                }) {
                    Text(isFollowing ? "Siguiendo" : "Seguir")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFollowing ? Color(.systemGray5) : Color.black)
                        .foregroundColor(isFollowing ? .black : .white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
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
                                    Capsule()
                                        .fill(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 10)
                
                // Contenido según tab
                Group {
                    switch selectedTab {
                    case .entrenamientos:
                        PerfilEntrenamientosView(profileID: profileUserID)
                    case .estadisticas:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                            .overlay(Text("📊 Gráfico de estadísticas").foregroundColor(.secondary))
                    case .logros:
                        Text("🏅 Logros del usuario (conectado más adelante)")
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await cargarPerfil()
                await verificarEstadoDeSeguimiento()
                await contarSeguidoresYSeguidos()
                await contarPosts()
            }
        }
    }
    
    // MARK: - Cargar perfil desde Supabase
    func cargarPerfil() async {
        do {
            let response = try await SupabaseManager.shared.client
                .from("perfil")
                .select()
                .eq("username", value: username)
                .single()
                .execute()
            
            let data = response.data
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.nombre = json["nombre"] as? String ?? username
                self.presentacion = json["presentacion"] as? String ?? ""
                self.avatarURL = json["avatar_url"] as? String
                self.profileUserID = json["id"] as? String ?? ""
            }
        } catch {
            self.error = "No se pudo cargar el perfil: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Verificar estado de seguimiento
    func verificarEstadoDeSeguimiento() async {
        guard let currentUserID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else { return }

        do {
            let response = try await SupabaseManager.shared.client
                .from("followers")
                .select()
                .eq("follower_id", value: currentUserID)
                .eq("followed_id", value: profileUserID)
                .execute()

            let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            isFollowing = json != nil
        } catch {
            print("❌ Error al verificar seguimiento: \(error)")
        }
    }

    // MARK: - Seguir usuario
    func seguirUsuario() async {
        guard let currentUserID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else { return }

        let insertData: [String: String] = [
            "follower_id": currentUserID,
            "followed_id": profileUserID
        ]

        do {
            _ = try await SupabaseManager.shared.client
                .from("followers")
                .insert(insertData)
                .execute()

            isFollowing = true
        } catch {
            print("❌ Error al seguir usuario: \(error)")
        }
    }

    // MARK: - Dejar de seguir
    func dejarDeSeguirUsuario() async {
        guard let currentUserID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else { return }

        do {
            _ = try await SupabaseManager.shared.client
                .from("followers")
                .delete()
                .eq("follower_id", value: currentUserID)
                .eq("followed_id", value: profileUserID)
                .execute()

            isFollowing = false
        } catch {
            print("❌ Error al dejar de seguir: \(error)")
        }
    }

    // MARK: - Alternar seguir/dejar de seguir
    func toggleFollow() async {
        guard let currentUserID = try? await SupabaseManager.shared.client.auth.session.user.id.uuidString else { return }

        do {
            if isFollowing {
                try await SupabaseManager.shared.client
                    .from("followers")
                    .delete()
                    .eq("follower_id", value: currentUserID)
                    .eq("followed_id", value: profileUserID)
                    .execute()
            } else {
                _ = try await SupabaseManager.shared.client
                    .from("followers")
                    .insert([
                        "follower_id": currentUserID,
                        "followed_id": profileUserID
                    ])
                    .execute()
            }

            isFollowing.toggle()
            await contarSeguidoresYSeguidos()
        } catch {
            print("❌ Error al alternar seguimiento: \(error)")
        }
    }

    // MARK: - Contar seguidores y seguidos
    func contarSeguidoresYSeguidos() async {
        do {
            // Contar SEGUIDORES (quién sigue a este usuario)
            let seguidoresResp = try await SupabaseManager.shared.client
                .from("followers")
                .select("follower_id", count: .exact)
                .eq("followed_id", value: profileUserID)
                .execute()
            seguidoresCount = seguidoresResp.count ?? 0

            // Contar SEGUIDOS (a quién sigue este usuario)
            let seguidosResp = try await SupabaseManager.shared.client
                .from("followers")
                .select("followed_id", count: .exact)
                .eq("follower_id", value: profileUserID)
                .execute()
            seguidosCount = seguidosResp.count ?? 0

        } catch {
            print("❌ Error al contar seguidores/seguidos: \(error)")
        }
    }
    
    // MARK: - Contar posts subidos por el usuario
    func contarPosts() async {
        guard !profileUserID.isEmpty else { return }

        do {
            let response = try await SupabaseManager.shared.client
                .from("posts")
                .select("id", count: .exact)
                .eq("autor_id", value: profileUserID)
                .execute()
            
            numeroDePosts = response.count ?? 0
        } catch {
            print("❌ Error al contar posts: \(error.localizedDescription)")
            numeroDePosts = 0
        }
    }
}
