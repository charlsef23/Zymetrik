import UIKit

class AvatarCache {
    static let shared = AvatarCache()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        cache.countLimit = 150
        cache.totalCostLimit = 64 * 1024 * 1024 // 64MB
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AvatarCache")
        createCacheDirectoryIfNeeded()
    }

    // MARK: Memory
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        saveImageToDisk(image, key: key)
    }

    func getImage(forKey key: String) -> UIImage? {
        if let image = cache.object(forKey: key as NSString) { return image }
        if let image = loadImageFromDisk(key: key) {
            let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
            cache.setObject(image, forKey: key as NSString, cost: cost)
            return image
        }
        return nil
    }

    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        removeImageFromDisk(key: key)
    }

    func clearCache() {
        cache.removeAllObjects()
        clearDiskCache()
    }

    // MARK: Disk
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func saveImageToDisk(_ image: UIImage, key: String) {
        // JPEG 0.8: buen equilibrio calidad/tamaño; usa WebP si ya lo tienes en el proyecto.
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let url = cacheDirectory.appendingPathComponent("\(key.hashValue)_v1.jpg")
        try? data.write(to: url, options: .atomic)
    }

    private func loadImageFromDisk(key: String) -> UIImage? {
        let url = cacheDirectory.appendingPathComponent("\(key.hashValue)_v1.jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func removeImageFromDisk(key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key.hashValue)_v1.jpg")
        try? fileManager.removeItem(at: url)
    }

    private func clearDiskCache() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for case let fileURL as URL in enumerator { try? fileManager.removeItem(at: fileURL) }
    }

    // MARK: Utils
    func getCacheSize() -> String {
        let memorySize = cache.totalCostLimit
        var diskSize: Int64 = 0
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    diskSize += Int64(fileSize)
                }
            }
        }
        let fmt = ByteCountFormatter()
        fmt.allowedUnits = [.useMB, .useKB]; fmt.countStyle = .file
        return "Memoria: \(fmt.string(fromByteCount: Int64(memorySize))), Disco: \(fmt.string(fromByteCount: diskSize)))"
    }

    // Invalida cachés
    func clearUserAvatar(userID: String) {
        let dir = self.cacheDirectory
        guard let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: nil) else { return }
        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent
            if name.contains("avatar_\(userID)") { try? fileManager.removeItem(at: fileURL) }
        }
    }

    func invalidateAvatar(for url: String) {
        removeImage(forKey: url)
    }
}
