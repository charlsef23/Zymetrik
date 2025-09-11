import UIKit

class AvatarCache {
    static let shared = AvatarCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AvatarCache")
        
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Memory Cache
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        saveImageToDisk(image, key: key)
    }
    
    func getImage(forKey key: String) -> UIImage? {
        // Primero intentar memoria
        if let image = cache.object(forKey: key as NSString) {
            return image
        }
        
        // Luego intentar disco
        if let image = loadImageFromDisk(key: key) {
            cache.setObject(image, forKey: key as NSString)
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
    
    // MARK: - Disk Cache
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let url = cacheDirectory.appendingPathComponent("\(key.hash).jpg")
        try? data.write(to: url)
    }
    
    private func loadImageFromDisk(key: String) -> UIImage? {
        let url = cacheDirectory.appendingPathComponent("\(key.hash).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    private func removeImageFromDisk(key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key.hash).jpg")
        try? fileManager.removeItem(at: url)
    }
    
    private func clearDiskCache() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        
        for case let fileURL as URL in enumerator {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Cache Statistics
    
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
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        
        return "Memoria: \(formatter.string(fromByteCount: Int64(memorySize))), Disco: \(formatter.string(fromByteCount: diskSize))"
    }
}

extension AvatarCache {
    // Limpiar cache cuando el usuario cambia avatar
    func clearUserAvatar(userID: String) {
        // Buscar y eliminar todas las entradas relacionadas con este usuario
        let cacheDirectory = self.cacheDirectory
        
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        
        for case let fileURL as URL in enumerator {
            let fileName = fileURL.lastPathComponent
            if fileName.contains("avatar_\(userID)") {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // Método para invalidar cache de avatar específico
    func invalidateAvatar(for url: String) {
        removeImage(forKey: url)
    }
}
