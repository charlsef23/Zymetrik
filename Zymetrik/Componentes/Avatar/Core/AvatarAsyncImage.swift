import SwiftUI
import UIKit

struct AvatarAsyncImage: View {
    let url: URL?
    let size: CGFloat
    var preloaded: UIImage?
    var showBorder: Bool
    var borderColor: Color
    var borderWidth: CGFloat
    var filter: AvatarFilter?
    var enableHaptics: Bool
    
    init(
        url: URL?,
        size: CGFloat,
        preloaded: UIImage? = nil,
        showBorder: Bool = true,
        borderColor: Color = .white,
        borderWidth: CGFloat = 2,
        filter: AvatarFilter? = nil,
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
        Group {
            if let pre = preloaded {
                Image(uiImage: filter?.apply(to: pre) ?? pre)
                    .resizable()
                    .scaledToFill()
            } else if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                if enableHaptics {
                                    HapticManager.shared.impact(.light)
                                }
                            }
                    case .failure:
                        fallbackView
                    @unknown default:
                        loadingView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            showBorder ?
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
                .shadow(color: .black.opacity(0.1), radius: 1)
            : nil
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        .accessibilityHidden(true)
    }
    
    private var loadingView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemGray5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.secondary)
            )
    }
    
    private var fallbackView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            )
    }
}
