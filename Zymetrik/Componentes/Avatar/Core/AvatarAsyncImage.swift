import SwiftUI
import UIKit

/// Versión turbo: usa `preloaded` si viene, si no, caché (memoria/disco) y luego red + downsample.
/// Evita `AsyncImage` para tener control de caché y tamaño real (reduce jank).
struct AvatarAsyncImage: View {
    let url: URL?
    let size: CGFloat
    var preloaded: UIImage?
    var showBorder: Bool
    var borderColor: Color
    var borderWidth: CGFloat
    var filter: ((UIImage) -> UIImage)?
    var enableHaptics: Bool

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        size: CGFloat,
        preloaded: UIImage? = nil,
        showBorder: Bool = true,
        borderColor: Color = .white,
        borderWidth: CGFloat = 2,
        filter: ((UIImage) -> UIImage)? = nil,
        enableHaptics: Bool = true
    ) {
        self.url = url
        self.size = size
        self.preloaded = preloaded
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.filter = filter
        self.enableHaptics = enableHaptics
    }

    var body: some View {
        ZStack {
            if let img = effectiveImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                loadingView
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            showBorder
            ? Circle().stroke(borderColor, lineWidth: borderWidth).shadow(color: .black.opacity(0.1), radius: 1)
            : nil
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        .accessibilityHidden(true)
        .task { await loadIfNeeded() }
        .onChange(of: url?.absoluteString) { _, _ in Task { await loadIfNeeded(reset: true) } }
    }

    /// Imagen efectiva (preloaded > cacheada > nil)
    private var effectiveImage: UIImage? {
        if let pre = preloaded { return filtered(pre) }
        if let uiImage { return filtered(uiImage) }
        return nil
    }

    private func filtered(_ image: UIImage) -> UIImage {
        guard let filter else { return image }
        return filter(image)
    }

    private func loadIfNeeded(reset: Bool = false) async {
        guard preloaded == nil else { return }               // si ya viene precargada, no cargamos nada
        guard let urlStr = url?.absoluteString, !urlStr.isEmpty else { return }
        if reset { await MainActor.run { uiImage = nil } }

        // 1) cache (memoria/disco) via AvatarCache
        if let cached = AvatarCache.shared.getImage(forKey: urlStr) {
            await MainActor.run { uiImage = cached }
            return
        }

        // 2) red + downsample
        await MainActor.run { isLoading = true }
        let image = await AvatarImageLoader.load(urlString: urlStr, targetSide: size)
        await MainActor.run {
            self.uiImage = image
            self.isLoading = false
            if image != nil, enableHaptics { HapticManager.shared.impact(.light) }
        }
    }

    private var loadingView: some View {
        Circle()
            .fill(
                LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(ProgressView().scaleEffect(0.7).tint(.secondary))
    }

    private var fallbackView: some View {
        Circle()
            .fill(
                LinearGradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            )
    }
}
