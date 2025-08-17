import Foundation
import Supabase

struct AppInitializer {
    let client = SupabaseManager.shared.client

    // ⬅️ ahora el closure es async
    func run(setProgress: @escaping (Double, String?) async -> Void) async throws {
        await setProgress(0.05, "Inicializando servicios…")
        try await Task.sleep(nanoseconds: 120_000_000)

        await setProgress(0.15, "Comprobando sesión…")
        let session = try await client.auth.session
        let userID = session.user.id

        await setProgress(0.30, "Cargando datos del perfil…")
        async let perfilReq: Perfil = client
            .from("perfil")
            .select("id, username, nombre, avatar_url")
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .decoded(to: Perfil.self)

        await setProgress(0.55, "Cargando feed…")
        async let postsReq: [Post] = SupabaseService.shared.fetchPosts(limit: 20)

        await setProgress(0.75, "Sincronizando favoritos…")
        async let favsReq: Set<UUID> = SupabaseService.shared.fetchFavoritosIDs()

        let (perfil, posts, favs) = try await (perfilReq, postsReq, favsReq)

        await setProgress(0.92, "Aplicando caché…")
        await MainActor.run {
            ContentStore.shared.perfil = perfil
            ContentStore.shared.posts = posts
            ContentStore.shared.favoritosIDs = favs
        }

        await setProgress(1.0, "¡Listo!")
    }
}
