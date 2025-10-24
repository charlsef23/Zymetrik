import Foundation
import SwiftUI

@MainActor
final class FeedStore: ObservableObject {
    static let shared = FeedStore()

    @Published var paraTiPosts: [Post] = []
    @Published var siguiendoPosts: [Post] = []
    @Published var isReady: Bool = false
    @Published var errorMessage: String? = nil

    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private init() {}

    // MARK: - Precarga completa
    func preloadAll() async {
        isReady = false
        errorMessage = nil
        do {
            let me = try await DMMessagingService.shared.currentUserID()

            async let paraTi = fetchAllParaTi(userID: me)
            async let siguiendo = fetchAllSiguiendo(userID: me)
            let (p1, p2) = try await (paraTi, siguiendo)

            self.paraTiPosts = p1.sorted { $0.fecha > $1.fecha }
            self.siguiendoPosts = p2.sorted { $0.fecha > $1.fecha }
            self.isReady = true
        } catch {
            self.errorMessage = "No se pudo cargar el feed: \(error.localizedDescription)"
            self.isReady = true
        }
    }

    // MARK: - Recarga manual (pull-to-refresh)
    func reload(selection: InicioView.FeedSelection) async {
        do {
            let me = try await DMMessagingService.shared.currentUserID()
            switch selection {
            case .paraTi:
                let full = try await fetchAllParaTi(userID: me)
                self.paraTiPosts = full.sorted { $0.fecha > $1.fecha }
            case .siguiendo:
                let full = try await fetchAllSiguiendo(userID: me)
                self.siguiendoPosts = full.sorted { $0.fecha > $1.fecha }
            }
        } catch {
            self.errorMessage = "No se pudo recargar: \(error.localizedDescription)"
        }
    }

    // MARK: - Cargas completas (sin paginación visual)
    private func fetchAllParaTi(userID: UUID) async throws -> [Post] {
        let pageSize = 500
        var all: [Post] = []
        var beforeCursor: Date? = nil

        while true {
            let params = FeedParams(
                p_after_ts: nil,
                p_before_ts: beforeCursor.map { iso.string(from: $0) },
                p_limit: pageSize,
                p_user: userID
            )

            let res = try await SupabaseManager.shared.client
                .rpc("get_feed_posts", params: params)
                .execute()

            let page = try res.decodedList(to: Post.self)
            if page.isEmpty { break }

            all.append(contentsOf: page)
            beforeCursor = page.last?.fecha
            if page.count < pageSize { break }
        }

        // Elimina duplicados
        var dict = [UUID: Post]()
        for p in all { dict[p.id] = p }
        return Array(dict.values)
    }

    private func fetchAllSiguiendo(userID: UUID) async throws -> [Post] {
        let pageSize = 500
        var all: [Post] = []
        var beforeCursor: Date? = nil

        while true {
            let page = try await SupabaseService.shared.fetchFollowingPosts(
                userID: userID,
                before: beforeCursor,
                limit: pageSize
            )
            if page.isEmpty { break }

            all.append(contentsOf: page)
            beforeCursor = page.last?.fecha
            if page.count < pageSize { break }
        }

        var dict = [UUID: Post]()
        for p in all { dict[p.id] = p }
        return Array(dict.values)
    }
}
