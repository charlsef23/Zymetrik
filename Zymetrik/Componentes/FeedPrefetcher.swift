import UIKit

actor FeedPrefetcher {
    static let shared = FeedPrefetcher()

    // cache in-memory simple (podrías usar NSCache)
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
        // avatar
        if avatarCache[post.autor_id] == nil, let a = post.avatar_url, let url = URL(string: a) {
            if let img = await FastImageLoader.downsampledImage(from: url, targetSize: CGSize(width: 40, height: 40)) {
                avatarCache[post.autor_id] = img
            }
        }

        // thumbnails
        var imgs: [UUID: UIImage] = [:]
        await withTaskGroup(of: (UUID, UIImage?)?.self) { group in
            for e in post.contenido {
                if let s = e.imagen_url, let url = URL(string: s) {
                    group.addTask(priority: .utility) {
                        let img = await FastImageLoader.downsampledImage(from: url, targetSize: CGSize(width: 120, height: 120))
                        return (e.id, img)
                    }
                }
            }
            for await pair in group {
                if let (id, img) = pair, let img {
                    imgs[id] = img
                }
            }
        }
        cache[post.id] = imgs
    }

    func images(for postID: UUID) -> [UUID: UIImage]? { cache[postID] }
    func avatar(for autorID: UUID) -> UIImage? { avatarCache[autorID] }
}
