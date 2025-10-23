import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import UIKit

// MARK: - Caché en memoria
final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSURL, UIImage>()
    private init() { cache.totalCostLimit = 50 * 1024 * 1024 } // ≈50MB
    func image(for url: NSURL) -> UIImage? { cache.object(forKey: url) }
    func insert(_ image: UIImage, for url: NSURL) {
        let bytes = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
        cache.setObject(image, forKey: url, cost: bytes)
    }
}

// MARK: - Downsampling
func downsampledImage(from data: Data, maxPixel: CGFloat) -> UIImage? {
    let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let src = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
    let downsampleOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, downsampleOptions as CFDictionary) else { return nil }
    return UIImage(cgImage: cg)
}

// MARK: - Loader
@MainActor
final class CachedImageLoader: ObservableObject {
    @Published var uiImage: UIImage?
    @Published var isLoading = false
    private var task: Task<Void, Never>?

    func load(from urlString: String?, maxPixel: CGFloat = 512) {
        guard let urlString, let url = URL(string: urlString) else { return }
        let nsurl = url as NSURL

        if let cached = ImageMemoryCache.shared.image(for: nsurl) {
            self.uiImage = cached
            return
        }

        task?.cancel()
        isLoading = true

        task = Task {
            defer { isLoading = false }
            var req = URLRequest(url: url)
            req.cachePolicy = .returnCacheDataElseLoad
            req.timeoutInterval = 20

            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                if Task.isCancelled { return }
                if let img = downsampledImage(from: data, maxPixel: maxPixel) {
                    ImageMemoryCache.shared.insert(img, for: nsurl)
                    self.uiImage = img
                }
            } catch { /* placeholder */ }
        }
    }

    func cancel() { task?.cancel() }
}

// MARK: - Vista
struct CachedAsyncImage<Placeholder: View>: View {
    let url: String?
    var maxPixel: CGFloat = 512
    var aspectRatio: CGFloat? = nil
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 12
    var placeholder: () -> Placeholder

    @StateObject private var loader = CachedImageLoader()

    var body: some View {
        ZStack {
            if let ui = loader.uiImage {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: contentMode)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .transition(.opacity)
            } else {
                placeholder()
                    .redacted(reason: .placeholder)
                    .overlay(ProgressView().scaleEffect(0.9))
                    .cornerRadius(cornerRadius)
            }
        }
        .task { loader.load(from: url, maxPixel: maxPixel) }
        .onDisappear { loader.cancel() }
        .accessibilityHidden(loader.uiImage == nil)
    }
}

// MARK: - Prefetch utilitario
func prefetchImages(urls: [String], maxPixel: CGFloat = 512) async {
    await withTaskGroup(of: Void.self) { group in
        for u in urls {
            group.addTask {
                guard let url = URL(string: u) else { return }
                let nsurl = url as NSURL
                if ImageMemoryCache.shared.image(for: nsurl) != nil { return }
                var req = URLRequest(url: url)
                req.cachePolicy = .returnCacheDataElseLoad
                req.timeoutInterval = 20
                if let (data, _) = try? await URLSession.shared.data(for: req),
                   let img = downsampledImage(from: data, maxPixel: maxPixel) {
                    ImageMemoryCache.shared.insert(img, for: nsurl)
                }
            }
        }
    }
}
