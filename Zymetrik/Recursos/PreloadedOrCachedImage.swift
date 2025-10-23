import SwiftUI
import UIKit

struct PreloadedOrCachedImage<Placeholder: View>: View {
    let preloaded: UIImage?
    let urlString: String?
    var maxPixel: CGFloat = 512
    var aspectRatio: CGFloat? = nil
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 12
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        if let ui = preloaded {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: contentMode)
                .clipped()
                .cornerRadius(cornerRadius)
                .transition(.opacity)
        } else {
            CachedAsyncImage(
                url: urlString,
                maxPixel: maxPixel,
                aspectRatio: aspectRatio,
                contentMode: contentMode,
                cornerRadius: cornerRadius,
                placeholder: placeholder
            )
        }
    }
}
