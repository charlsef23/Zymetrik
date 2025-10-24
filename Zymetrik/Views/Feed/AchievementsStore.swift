import Foundation
import SwiftUI

@MainActor
final class AchievementsStore: ObservableObject {
    static let shared = AchievementsStore()

    /// Logros por autor
    @Published private(set) var achievementsByAuthor: [UUID: [LogroConEstado]] = [:]

    private init() {}

    func preloadForCurrentUser() async {
        guard let me = SupabaseManager.shared.client.auth.currentSession?.user.id else { return }
        if achievementsByAuthor[me] != nil { return }
        await load(authorId: me)
    }

    func reload(authorId: UUID) async {
        await load(authorId: authorId)
    }

    func achievements(for author: UUID) -> [LogroConEstado] {
        achievementsByAuthor[author] ?? []
    }

    // MARK: - Private
    private func load(authorId: UUID) async {
        do {
            let session = try? await SupabaseService.shared.client.auth.session
            let me = session?.user.id

            let all: [LogroConEstado]
            if let me, me == authorId {
                all = try await SupabaseService.shared.fetchLogrosCompletos()
            } else {
                all = try await SupabaseService.shared.fetchLogrosCompletos(autorId: authorId)
            }
            achievementsByAuthor[authorId] = all
        } catch {
            // silencioso
        }
    }
}
