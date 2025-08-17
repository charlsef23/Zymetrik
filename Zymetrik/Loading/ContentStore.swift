import SwiftUI

@MainActor
final class ContentStore: ObservableObject {
    static let shared = ContentStore()

    @Published var perfil: Perfil?
    @Published var posts: [Post] = []
    @Published var favoritosIDs: Set<UUID> = []

    // Recargas puntuales desde dentro de la app
    func reloadFeed() async {
        do {
            let nuevos = try await SupabaseService.shared.fetchPosts()
            posts = nuevos
        } catch {
            print("❌ Error recargando feed:", error)
        }
    }

    func reloadFavoritos() async {
        do {
            favoritosIDs = try await SupabaseService.shared.fetchFavoritosIDs()
        } catch {
            print("❌ Error recargando favoritos:", error)
        }
    }
}
