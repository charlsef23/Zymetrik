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
    @State private var numeroDePosts = 0
    @State private var seguidoresCount = 0
    @State private var seguidosCount = 0
    @State private var profileUserID: String = ""
    @State private var isMe = false
    @State private var working = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Foto y nombre
                VStack(spacing: 8) {
                    avatar(avatarURL)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())

                    Text(nombre.isEmpty ? username : nombre)
                        .font(.title2).fontWeight(.bold)

                    Text(presentacion.isEmpty ? "📍 Entrenando cada día\n💪 Fitness · Salud · Comunidad" : presentacion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Contadores
                HStack {
                    Spacer()
                    counter(title: "Entrenos", value: numeroDePosts)
                    Spacer()
                    NavigationLink(destination: ListaSeguidoresView(userID: profileUserID)) {
                        counter(title: "Seguidores", value: seguidoresCount)
                    }
                    Spacer()
                    NavigationLink(destination: ListaSeguidosView(userID: profileUserID)) {
                        counter(title: "Siguiendo", value: seguidosCount)
                    }
                    Spacer()
                }

                // Botón seguir (ocúltalo si es tu perfil)
                if !isMe && !profileUserID.isEmpty {
                    Button(action: { Task { await toggleFollow() } }) {
                        Text(isFollowing ? "Siguiendo" : "Seguir")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFollowing ? Color(.systemGray5) : Color.black)
                            .foregroundColor(isFollowing ? .black : .white)
                            .cornerRadius(10)
                    }
                    .disabled(working)
                    .padding(.horizontal)
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
                .padding(.vertical, 10)

                // Contenido
                Group {
                    switch selectedTab {
                    case .entrenamientos:
                        if !profileUserID.isEmpty {
                            PerfilEntrenamientosView(profileID: profileUserID)
                        } else {
                            ProgressView().padding()
                        }
                    case .estadisticas:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                            .overlay(Text("📊 Gráfico de estadísticas").foregroundColor(.secondary))
                    case .logros:
                        Text("🏅 Logros del usuario (próximamente)")
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await cargarPerfil()
            await prepararEstado()
        }
    }

    // MARK: - Data

    private func cargarPerfil() async {
        defer { isLoading = false }
        do {
            let res = try await SupabaseManager.shared.client
                .from("perfil")
                .select("id,nombre,username,presentacion,avatar_url")
                .eq("username", value: username)
                .single()
                .execute()

            struct Row: Decodable {
                let id: String
                let nombre: String?
                let username: String
                let presentacion: String?
                let avatar_url: String?
            }
            let row = try res.decoded(to: Row.self)

            profileUserID = row.id
            nombre = row.nombre ?? row.username
            presentacion = row.presentacion ?? ""
            avatarURL = row.avatar_url

            // Contadores
            async let postsCount: Int = {
                let r = try await SupabaseManager.shared.client
                    .from("posts")
                    .select("id", count: .exact)
                    .eq("autor_id", value: row.id)
                    .execute()
                return r.count ?? 0
            }()

            async let followersCount: Int = {
                try await FollowersService.shared.countFollowers(userID: row.id)
            }()

            async let followingCount: Int = {
                try await FollowersService.shared.countFollowing(userID: row.id)
            }()

            let (p, f1, f2) = try await (postsCount, followersCount, followingCount)
            numeroDePosts = p
            seguidoresCount = f1
            seguidosCount = f2

        } catch {
            self.error = "No se pudo cargar el perfil: \(error.localizedDescription)"
        }
    }

    private func prepararEstado() async {
        do {
            let me = try await SupabaseManager.shared.client.auth.session.user.id.uuidString
            isMe = (me == profileUserID)
            if !isMe && !profileUserID.isEmpty {
                isFollowing = try await FollowersService.shared.isFollowing(currentUserID: me, targetUserID: profileUserID)
            }
        } catch {
            isFollowing = false
        }
    }

    // MARK: - Follow toggle

    private func toggleFollow() async {
        guard !profileUserID.isEmpty else { return }
        guard !isMe else { return }

        working = true
        let wasFollowing = isFollowing
        // Optimistic UI
        isFollowing.toggle()
        seguidoresCount += wasFollowing ? -1 : 1

        do {
            if wasFollowing {
                _ = try await FollowersService.shared.unfollow(targetUserID: profileUserID)
                FollowNotification.post(targetUserID: profileUserID, didFollow: false)
            } else {
                _ = try await FollowersService.shared.follow(targetUserID: profileUserID)
                FollowNotification.post(targetUserID: profileUserID, didFollow: true)
            }
        } catch {
            // revert
            isFollowing = wasFollowing
            seguidoresCount += wasFollowing ? 1 : -1
            print("❌ toggleFollow error: \(error)")
        }
        working = false
    }

    // MARK: - UI helpers

    @ViewBuilder
    private func avatar(_ urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { img in
                img.resizable()
            } placeholder: { ProgressView() }
        } else {
            Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray)
        }
    }

    private func counter(title: String, value: Int) -> some View {
        VStack {
            Text("\(value)").font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
    }
}
