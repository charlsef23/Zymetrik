import Foundation
import SwiftUI
import Supabase

enum PerfilTab: String, CaseIterable {
    case entrenamientos = "Entrenos"
    case estadisticas = "Estadísticas"
    case logros = "Logros"
}

// MARK: - DTO del perfil (ajusta campos si tu tabla cambia)
struct PerfilDTO: Decodable {
    let id: String
    let nombre: String?
    let username: String?
    let presentacion: String?
    let enlaces: String?
    let avatar_url: String?
}

@MainActor
final class PerfilViewModel: ObservableObject {
    // Estado que antes estaba en la vista
    @Published var userID: String = ""
    @Published var nombre: String = "Cargando..."
    @Published var username: String = "..."
    @Published var presentacion: String = ""
    @Published var enlaces: String = ""
    @Published var imagenPerfilURL: String? = nil

    @Published var numeroDePosts: Int = 0
    @Published var seguidoresCount: Int = 0
    @Published var siguiendoCount: Int = 0

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Punto de entrada
    func cargarDatosCompletos() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.cargarDatosIniciales() }
            group.addTask { await self.cargarContadoresSeguidores() }
            group.addTask { await self.cargarNumeroDePosts() }
        }
    }

    // MARK: - Cargar datos iniciales
    func cargarDatosIniciales() async {
        do {
            _ = try await client.auth.session
            await cargarPerfilDesdeSupabase()
        } catch {
            print("❌ Error al obtener sesión: \(error)")
        }
    }

    // MARK: - Cargar perfil desde Supabase
    // Reemplaza TODO el método por este:
    func cargarPerfilDesdeSupabase() async {
        do {
            let session = try await client.auth.session
            let uid = session.user.id.uuidString
            self.userID = uid

            // Pide columnas explícitas para que no infiera Void
            let response = try await client
                .from("perfil")
                .select("id,nombre,username,presentacion,enlaces,avatar_url")
                .eq("id", value: uid)
                .single()
                .execute()

            // Decodifica con JSONDecoder desde response.data
            // En supabase-swift, data suele ser Data (no opcional)
            let data = response.data

            // Intenta decodificar a tu DTO
            if let perfil = try? JSONDecoder().decode(PerfilDTO.self, from: data) {
                self.nombre = perfil.nombre ?? ""
                self.username = perfil.username ?? ""
                self.presentacion = perfil.presentacion ?? ""
                self.enlaces = perfil.enlaces ?? ""
                self.imagenPerfilURL = perfil.avatar_url
                return
            }

            // Como fallback (por si llega con keys inesperadas)
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
        }
    }
    // MARK: - Cargar seguidores y siguiendo
    func cargarContadoresSeguidores() async {
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
        }
    }

    // MARK: - Cargar número de posts
    func cargarNumeroDePosts() async {
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
        }
    }
}
