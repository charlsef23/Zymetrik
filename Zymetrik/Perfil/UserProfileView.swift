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

    private var perfilUUID: UUID? { UUID(uuidString: profileUserID) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                // Header
                VStack(spacing: 8) {
                    avatar(avatarURL)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())

                    Text(nombre.isEmpty ? username : nombre)
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
                    counter(title: "Entrenos", value: numeroDePosts)
                    Spacer()
                    NavigationLink {
                        ListaSeguidoresView(userID: profileUserID)
                    } label: {
                        counter(title: "Seguidores", value: seguidoresCount)
                    }
                    Spacer()
                    NavigationLink {
                        ListaSeguidosView(userID: profileUserID)
                    } label: {
                        counter(title: "Siguiendo", value: seguidosCount)
                    }
                    Spacer()
                }

                // Seguir / Siguiendo (oculto en propio perfil)
                if !isMe && !profileUserID.isEmpty {
                    Button {
                        Task { await toggleFollow() }
                    } label: {
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

                // Contenido (borderless / full-bleed)
                tabContent
                    .padding(.vertical, 4) // sin padding horizontal → full-bleed
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await cargarPerfil()
            await prepararEstado()
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .entrenamientos:
            entrenosContent
        case .estadisticas:
            estadisticasContent
        case .logros:
            logrosContent
        }
    }

    @ViewBuilder
    private var entrenosContent: some View {
        if !profileUserID.isEmpty {
            PerfilEntrenamientosView(profileID: profileUserID)
        } else {
            ProgressView().padding()
        }
    }

    @ViewBuilder
    private var estadisticasContent: some View {
        if let perfilUUID {
            PerfilEstadisticasView(perfilId: perfilUUID)
        } else {
            ProgressView("Cargando estadísticas…")
                .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private var logrosContent: some View {
        if let perfilUUID {
            PerfilLogrosView(perfilId: perfilUUID)  
        } else {
            ProgressView().padding()
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
        guard !profileUserID.isEmpty, !isMe else { return }
        working = true
        let wasFollowing = isFollowing

        // UI optimista
        isFollowing.toggle()
        seguidoresCount += wasFollowing ? -1 : 1

        do {
            if wasFollowing {
                let result = try await FollowersService.shared.unfollow(targetUserID: profileUserID)
                self.seguidoresCount = result.targetFollowers
            } else {
                let result = try await FollowersService.shared.follow(targetUserID: profileUserID)
                self.seguidoresCount = result.targetFollowers
            }
        } catch {
            // revertir si falla
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
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }
    }

    private func counter(title: String, value: Int) -> some View {
        VStack {
            Text("\(value)").font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
    }
}
