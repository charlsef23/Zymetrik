import Foundation
import SwiftUI

@MainActor
final class StatsStore: ObservableObject {
    static let shared = StatsStore()

    /// Ejercicios + sesiones por autor
    @Published private(set) var statsByAuthor: [UUID: [(ejercicio: EjercicioPostContenido, sesiones: [SesionEjercicio])]] = [:]

    private init() {}

    /// Precarga para el usuario actual. Construye la lista a partir de posts ya en memoria + sesiones cacheadas.
    func preloadForCurrentUser(feedStore: FeedStore) async {
        guard let me = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
        // Si ya tenemos algo, no rehacer innecesariamente
        if statsByAuthor[me] != nil { return }

        // Construye desde feed precargado (Para ti + Siguiendo), filtrando por autor == me
        let posts = (feedStore.paraTiPosts + feedStore.siguiendoPosts).filter { $0.autor_id == me }
        await buildStats(for: me, from: posts)
    }

    /// Recarga forzada para un autor específico (silenciosa para la UI).
    func reload(authorId: UUID) async {
        do {
            let posts = try await SupabaseService.shared.fetchPostsDelUsuario(autorId: authorId)
            await buildStats(for: authorId, from: posts)
        } catch {
            // silencioso
        }
    }

    /// Obtiene (si existe) las stats ya en memoria.
    func stats(for author: UUID) -> [(EjercicioPostContenido, [SesionEjercicio])] {
        statsByAuthor[author] ?? []
    }

    // MARK: - Private

    private func buildStats(for authorId: UUID, from posts: [Post]) async {
        var uniqueIds = Set<UUID>()
        var metaById: [UUID: EjercicioPostContenido] = [:]
        for p in posts {
            for e in p.contenido {
                if metaById[e.id] == nil { metaById[e.id] = e }
                uniqueIds.insert(e.id)
            }
        }
        guard !uniqueIds.isEmpty else {
            statsByAuthor[authorId] = []
            return
        }

        var acumulado: [(EjercicioPostContenido, [SesionEjercicio])] = []

        await withTaskGroup(of: (UUID, [SesionEjercicio]).self) { group in
            for id in uniqueIds {
                group.addTask {
                    let sesiones = await SupabaseService.shared.obtenerSesionesParaCached(ejercicioID: id, autorId: authorId)
                    return (id, sesiones)
                }
            }
            for await (id, sesiones) in group {
                if !sesiones.isEmpty, let meta = metaById[id] {
                    acumulado.append((meta, sesiones))
                }
            }
        }

        acumulado.sort { ($0.1.last?.fecha ?? .distantPast) > ($1.1.last?.fecha ?? .distantPast) }
        statsByAuthor[authorId] = acumulado
    }
}
