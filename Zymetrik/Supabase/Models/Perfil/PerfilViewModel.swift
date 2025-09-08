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
        // Escucha cambios de follow para refrescar contadores
        followObserver = NotificationCenter.default.addObserver(
            forName: .followStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.cargarContadoresSeguidores() }
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

    public func refrescar() async { await cargarDatosCompletos() }

    public func cargarDatosIniciales() async {
        do {
            _ = try await client.auth.session
            await cargarPerfilDesdeSupabase()
        } catch {
            print("❌ Error al obtener sesión: \(error)")
            self.errorText = "No hay sesión activa."
        }
    }

    public func cargarPerfilDesdeSupabase() async {
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

            let data = response.data

            if let perfil = try? JSONDecoder().decode(PerfilDTO.self, from: data) {
                self.nombre = perfil.nombre ?? ""
                self.username = perfil.username ?? ""
                self.presentacion = perfil.presentacion ?? ""
                self.enlaces = perfil.enlaces ?? ""
                self.imagenPerfilURL = perfil.avatar_url
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.nombre = json["nombre"] as? String ?? ""
                self.username = json["username"] as? String ?? ""
                self.presentacion = json["presentacion"] as? String ?? ""
                self.enlaces = json["enlaces"] as? String ?? ""
                self.imagenPerfilURL = json["avatar_url"] as? String
            } else {
                print("❌ No se pudo decodificar la respuesta de perfil")
            }

        } catch {
            print("❌ Error al cargar perfil: \(error)")
            self.errorText = "Error al cargar perfil."
        }
    }

    public func cargarContadoresSeguidores() async {
        do {
            let session = try await client.auth.session
            let uid = session.user.id.uuidString

            let seguidoresResponse = try await client
                .from("followers")
                .select("follower_id", count: .exact)
                .eq("followed_id", value: uid)
                .execute()
            self.seguidoresCount = seguidoresResponse.count ?? 0

            let siguiendoResponse = try await client
                .from("followers")
                .select("followed_id", count: .exact)
                .eq("follower_id", value: uid)
                .execute()
            self.siguiendoCount = siguiendoResponse.count ?? 0

        } catch {
            print("❌ Error al cargar contadores: \(error)")
            self.errorText = "Error al cargar contadores."
        }
    }

    public func cargarNumeroDePosts() async {
        do {
            let session = try await client.auth.session
            let uid = session.user.id.uuidString

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
