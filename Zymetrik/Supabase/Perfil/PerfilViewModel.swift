import Foundation
import Supabase

@MainActor
public final class PerfilViewModel: ObservableObject {

    // Datos
    @Published public var userID: String = ""
    @Published public var nombre: String = "Cargando..."
    @Published public var username: String = "..."
    @Published public var presentacion: String = ""
    @Published public var enlaces: String = ""
    @Published public var imagenPerfilURL: String? = nil

    // Contadores
    @Published public var numeroDePosts: Int = 0
    @Published public var seguidoresCount: Int = 0
    @Published public var siguiendoCount: Int = 0

    // Estado
    @Published public var isLoading: Bool = false
    @Published public var errorText: String? = nil
    @Published public var lastUpdated: Date? = nil

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var followObserver: NSObjectProtocol?

    public init() {
        // ⚠️ IMPORTANTE: no accedemos a self fuera del MainActor en el closure.
        followObserver = NotificationCenter.default.addObserver(
            forName: FollowNotification.name,
            object: nil,
            queue: nil   // dejamos que ejecute en el hilo que sea y saltamos al MainActor abajo
        ) { [weak self] note in
            // Mover TODA la interacción con self al MainActor:
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let info = note.userInfo else { return }

                let myId = self.userID
                let targetID = info["targetUserID"] as? String
                let followerID = info["followerID"] as? String
                let targetFollowers = info["targetFollowers"] as? Int
                let meFollowing = info["meFollowing"] as? Int

                // Si yo soy el seguido -> actualiza seguidoresCount
                if let targetID, targetID == myId {
                    if let tf = targetFollowers {
                        self.seguidoresCount = tf
                    } else {
                        await self.cargarContadoresSeguidores()
                    }
                }

                // Si yo soy quien sigue -> actualiza siguiendoCount
                if let followerID, followerID == myId {
                    if let mf = meFollowing {
                        self.siguiendoCount = mf
                    } else {
                        await self.cargarContadoresSeguidores()
                    }
                }
            }
        }
    }

    deinit {
        if let token = followObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - API
    public func cargarDatosCompletos() async {
        isLoading = true
        errorText = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.cargarDatosIniciales() }
            group.addTask { await self.cargarContadoresSeguidores() }
            group.addTask { await self.cargarNumeroDePosts() }
        }
        isLoading = false
        lastUpdated = Date()
    }

    public func cargarDatosIniciales() async {
        do {
            let session = try await client.auth.session
            let uid = session.user.id.uuidString
            self.userID = uid

            let response = try await client
                .from("perfil")
                .select("id,nombre,username,presentacion,enlaces,avatar_url")
                .eq("id", value: uid)
                .single()
                .execute()

            if let perfil = try? JSONDecoder().decode(PerfilDTO.self, from: response.data) {
                self.nombre = perfil.nombre ?? ""
                self.username = perfil.username ?? ""
                self.presentacion = perfil.presentacion ?? ""
                self.enlaces = perfil.enlaces ?? ""
                self.imagenPerfilURL = perfil.avatar_url
            } else if
                let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            {
                self.nombre = json["nombre"] as? String ?? ""
                self.username = json["username"] as? String ?? ""
                self.presentacion = json["presentacion"] as? String ?? ""
                self.enlaces = json["enlaces"] as? String ?? ""
                self.imagenPerfilURL = json["avatar_url"] as? String
            }

        } catch {
            print("❌ Error al cargar perfil: \(error)")
            self.errorText = "Error al cargar perfil."
        }
    }

    public func cargarContadoresSeguidores() async {
        do {
            let uid = try await client.auth.session.user.id.uuidString
            async let c1 = FollowersService.shared.countFollowers(userID: uid)
            async let c2 = FollowersService.shared.countFollowing(userID: uid)
            let (followers, following) = try await (c1, c2)
            self.seguidoresCount = followers
            self.siguiendoCount = following
        } catch {
            print("❌ Error al cargar contadores: \(error)")
            self.errorText = "Error al cargar contadores."
        }
    }

    public func cargarNumeroDePosts() async {
        do {
            let uid = try await client.auth.session.user.id.uuidString
            let response = try await client
                .from("posts")
                .select("id", count: .exact)
                .eq("autor_id", value: uid)
                .execute()
            self.numeroDePosts = response.count ?? 0
        } catch {
            print("❌ Error al contar posts: \(error)")
            self.errorText = "Error al contar posts."
        }
    }
}
