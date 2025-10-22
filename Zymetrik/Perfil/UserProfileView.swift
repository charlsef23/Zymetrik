import SwiftUI
import Supabase

struct UserProfileView: View {
    let username: String
    @Environment(\.colorScheme) private var colorScheme

    @State private var nombre: String = ""
    @State private var avatarURL: String?
    @State private var presentacion: String = ""
    @State private var isLoading = true
    @State private var error: String?

    @State private var selectedTab: PerfilTab = .entrenamientos
    @State private var isFollowing = false
    @State private var followsMe = false
    @State private var numeroDePosts = 0
    @State private var seguidoresCount = 0
    @State private var seguidosCount = 0
    @State private var profileUserID: String = ""
    @State private var isMe = false
    @State private var working = false

    @State private var dmConvID: UUID? = nil
    @State private var dmOther: PerfilLite? = nil
    @State private var showDMChat = false

    // ⬇️ Estado de bloqueo
    @State private var iBlockHim = false      // yo bloqueo a este usuario
    @State private var heBlocksMe = false     // él me bloquea a mí

    private var perfilUUID: UUID? { UUID(uuidString: profileUserID) }

    // ✅ Comodines
    private var isBlockedEither: Bool { iBlockHim || heBlocksMe }
    private var canSeeProfile: Bool { !isBlockedEither }   // UX: ocultamos contenido si hay bloqueo

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                // Header
                headerBar
                    .padding(.horizontal)

                // Info de perfil
                VStack(spacing: 8) {
                    avatar(avatarURL)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())

                    Text(nombre.isEmpty ? username : nombre)
                        .font(.title2)
                        .fontWeight(.bold)

                    if !presentacion.isEmpty {
                        Text(presentacion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top)

                // Banner de estado de bloqueo
                if heBlocksMe {
                    blockedBanner(
                        text: "Este usuario te ha bloqueado. No puedes ver su contenido ni interactuar."
                    )
                } else if iBlockHim {
                    blockedBanner(
                        text: "Has bloqueado a este usuario. No verás su contenido ni podréis interactuar."
                    )
                }

                // Contadores (solo visibles si NO hay bloqueo)
                if canSeeProfile {
                    HStack {
                        Spacer()
                        counter(title: "Entrenos", value: numeroDePosts)
                        Spacer()
                        NavigationLink {
                            ListaSeguidoresView(userID: profileUserID)
                        } label: {
                            counter(title: "Seguidores", value: seguidoresCount)
                                .foregroundColor(.followNumber)
                        }
                        Spacer()
                        NavigationLink {
                            ListaSeguidosView(userID: profileUserID)
                        } label: {
                            counter(title: "Siguiendo", value: seguidosCount)
                                .foregroundColor(.followNumber)
                        }
                        Spacer()
                    }
                }

                // Acciones (Seguir / Mensaje) — ocultas si hay bloqueo o es mi perfil
                if !isMe && !profileUserID.isEmpty && !isBlockedEither {
                    HStack(spacing: 12) {
                        Button {
                            Task { await toggleFollow() }
                        } label: {
                            Text(isFollowing ? "Siguiendo" : (followsMe ? "Te sigue" : "Seguir"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFollowing ? Color(.systemGray5) : (colorScheme == .dark ? .white : .black))
                                .foregroundColor(isFollowing ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .black : .white))
                                .cornerRadius(10)
                        }
                        .disabled(working)

                        Button {
                            Task { await startDM() }
                        } label: {
                            Text("Mensaje")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.backgroundMensaje)
                                .foregroundColor(.foregroundMensaje)
                                .cornerRadius(10)
                        }
                        .disabled(working)
                    }
                    .padding(.horizontal)
                }

                // Tabs + Contenido (ocultos si hay bloqueo)
                if canSeeProfile {
                    HStack {
                        ForEach(PerfilTab.allCases, id: \.self) { tab in
                            Button { selectedTab = tab } label: {
                                Text(tab.rawValue)
                                    .fontWeight(selectedTab == tab ? .bold : .regular)
                                    .foregroundColor(selectedTab == tab ? .primary : .gray)
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

                    tabContent
                        .padding(.vertical, 4)
                } else {
                    // Placeholder al estar bloqueado
                    ContentUnavailableView(
                        "Contenido no disponible",
                        systemImage: "eye.slash",
                        description: Text("No puedes ver el contenido de este perfil.")
                    )
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .task {
            await cargarPerfil()
            await prepararEstado()
        }
        .navigationDestination(isPresented: $showDMChat) {
            if let convID = dmConvID {
                DMChatView(conversationID: convID, other: dmOther)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Text("@\(username)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            // Botón de tres puntos con acciones
            if !isMe && !profileUserID.isEmpty {
                Menu {
                    if iBlockHim {
                        // Mostrar Desbloquear si yo lo tengo bloqueado
                        Button(role: .destructive) {
                            Task { await toggleBlock() }
                        } label: {
                            Label("Desbloquear", systemImage: "hand.raised.slash.fill")
                        }
                    } else if !heBlocksMe {
                        // Mostrar Bloquear si no me ha bloqueado a mí
                        Button {
                            Task { await toggleBlock() }
                        } label: {
                            Label("Bloquear", systemImage: "hand.raised.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3.weight(.semibold))
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .disabled(working)
            }
        }
    }

    // MARK: - Banner bloqueado
    private func blockedBanner(text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
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

            // Contadores (si el backend deja ver; con RLS, fallará si no procede)
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
                async let a = FollowersService.shared.isFollowing(currentUserID: me, targetUserID: profileUserID)
                async let b = FollowersService.shared.doesFollowMe(currentUserID: me, targetUserID: profileUserID)
                async let c = BlockService.shared.iBlock(targetUserID: profileUserID)
                async let d = BlockService.shared.blocksMe(targetUserID: profileUserID)

                let (af, bf, ib, hb) = try await (a, b, c, d)
                isFollowing = af
                followsMe  = bf
                iBlockHim  = ib
                heBlocksMe = hb
            }
        } catch {
            isFollowing = false
            iBlockHim = false
            heBlocksMe = false
        }
    }

    // MARK: - Follow toggle (no se muestra si hay bloqueo)
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

    // MARK: - Bloquear / Desbloquear
    private func toggleBlock() async {
        guard !profileUserID.isEmpty, !isMe else { return }
        working = true
        defer { working = false }

        do {
            let status = try await BlockService.shared.toggleBlock(targetUserID: profileUserID)
            if status == "blocked" {
                iBlockHim = true
                // si lo bloqueo, oculto follow y corroijo contador si estaba siguiendo
                if isFollowing {
                    isFollowing = false
                    seguidoresCount = max(0, seguidoresCount - 1)
                }
            } else {
                iBlockHim = false
            }
        } catch {
            print("❌ toggleBlock error:", error)
        }
    }

    // MARK: - Mensaje directo (no disponible si bloqueo)
    private func startDM() async {
        guard let uid = perfilUUID else { return }
        if isBlockedEither { return }

        do {
            let convID = try await DMMessagingService.shared.getOrCreateDM(with: uid)
            await MainActor.run {
                self.dmConvID = convID
                self.dmOther = PerfilLite(id: uid, username: username, avatar_url: avatarURL)
                self.showDMChat = true
            }
        } catch {
            print("❌ startDM error:", error)
        }
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
