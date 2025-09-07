import SwiftUI
import UIKit

struct AvatarAsyncImage: View {
    let url: URL?
    let size: CGFloat
    var preloaded: UIImage? = nil

    init(url: URL?, size: CGFloat, preloaded: UIImage? = nil) {
        self.url = url
        self.size = size
        self.preloaded = preloaded
    }

    var body: some View {
        Group {
            if let pre = preloaded {
                Image(uiImage: pre)
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Circle().fill(Color(.secondarySystemBackground))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
