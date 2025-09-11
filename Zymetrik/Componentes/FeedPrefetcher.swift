import UIKit

// MARK: - FeedPrefetcher (PATCH)
actor FeedPrefetcher {
    static let shared = FeedPrefetcher()

    private var cache: [UUID: [UUID: UIImage]] = [:] // postID -> (ejercicioID -> image)
    private var avatarCache: [UUID: UIImage] = [:]    // autor_id -> avatar

    func prefetch(for posts: [Post]) async {
        await withTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask(priority: .utility) { [weak self] in
                    guard let self else { return }
                    await self.prefetchPost(post)
                }
            }
        }
    }

    private func prefetchPost(_ post: Post) async {
        // Avatar
        if avatarCache[post.autor_id] == nil,
           let url = post.avatar_url.validHTTPURL { // 👈 valida http(s)
            if let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 40, height: 40)) {
                avatarCache[post.autor_id] = img
            }
        }

        // Thumbnails ejercicios
        var imgs: [UUID: UIImage] = [:]
        await withTaskGroup(of: (UUID, UIImage?)?.self) { group in
            for e in post.contenido {
                if let s = e.imagen_url,
                   let url = s.validHTTPURL { // 👈 valida http(s)
                    group.addTask(priority: .utility) {
                        let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 120, height: 120))
                        return (e.id, img)
                    }
                }
            }
            for await pair in group {
                if let (id, img) = pair, let img { imgs[id] = img }
            }
        }
        cache[post.id] = imgs
    }

    func images(for postID: UUID) -> [UUID: UIImage]? { cache[postID] }
    func avatar(for autorID: UUID) -> UIImage? { avatarCache[autorID] }
}
