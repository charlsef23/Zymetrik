import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Central store to preload exercises and cache their images at app launch
/// so that lists can render immediately without showing loading spinners.
final class ExercisesStore: ObservableObject {
    static let shared = ExercisesStore()

    @Published var ejercicios: [Ejercicio] = []
    @Published var isPreloading: Bool = false

    #if canImport(UIKit)
    private let imageCache = NSCache<NSString, UIImage>()
    #endif

    private var preloadTask: Task<Void, Never>? = nil

    func ensurePreloaded() {
        if ejercicios.isEmpty && !isPreloading {
            preloadAll()
        }
    }

    func preloadAll() {
        // Cancel any previous preload
        preloadTask?.cancel()
        isPreloading = true
        preloadTask = Task {
            defer { Task { @MainActor in self.isPreloading = false } }
            do {
                let fetched = try await SupabaseService.shared.fetchEjerciciosConFavoritos()
                await MainActor.run {
                    self.ejercicios = fetched
                }
                // Prefetch images best-effort
                await prefetchImages(for: fetched)
            } catch {
                // Keep silent; views will fallback to their own loaders
                #if DEBUG
                print("❌ ExercisesStore preload error:", error)
                #endif
            }
        }
    }

    private func prefetchImages(for items: [Ejercicio]) async {
        await withTaskGroup(of: Void.self) { group in
            for e in items {
                guard let url = urlForImage(of: e) else { continue }
                #if canImport(UIKit)
                if image(for: url) != nil { continue }
                #endif
                group.addTask { [weak self] in
                    guard let self else { return }
                    if Task.isCancelled { return }
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        #if canImport(UIKit)
                        if let img = UIImage(data: data) {
                            await MainActor.run { self.setImage(img, for: url) }
                        }
                        #endif
                    } catch {
                        // ignore individual failures
                    }
                }
            }
        }
    }

    private func urlForImage(of e: Ejercicio) -> URL? {
        // Try common property names dynamically via Mirror
        // We support properties named: imagenURL, imagenUrl, imageURL, imageUrl (case-insensitive)
        // and accept either URL or String types.
        let wantedKeys: Set<String> = ["imagenurl", "imageurl"]

        let mirror = Mirror(reflecting: e)
        for child in mirror.children {
            guard let rawLabel = child.label else { continue }
            let label = rawLabel.lowercased()
            // Normalize camelCase variants ending with "url"
            guard wantedKeys.contains(label) || wantedKeys.contains(label.replacingOccurrences(of: "url", with: "url")) else { continue }

            switch child.value {
            case let url as URL:
                return url
            case let str as String:
                if let url = URL(string: str), !str.isEmpty { return url }
            default:
                // Also try Optional<URL> or Optional<String>
                let mirrorValue = Mirror(reflecting: child.value)
                if mirrorValue.displayStyle == .optional, let some = mirrorValue.children.first?.value {
                    if let url = some as? URL { return url }
                    if let str = some as? String, let url = URL(string: str), !str.isEmpty { return url }
                }
            }
        }
        return nil
    }

    #if canImport(UIKit)
    func image(for url: URL) -> UIImage? {
        imageCache.object(forKey: url.absoluteString as NSString)
    }

    func setImage(_ image: UIImage, for url: URL) {
        imageCache.setObject(image, forKey: url.absoluteString as NSString)
    }
    #endif
}
