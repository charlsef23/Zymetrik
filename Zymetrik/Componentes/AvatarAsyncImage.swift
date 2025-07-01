import SwiftUI

struct AvatarAsyncImage: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure(_):
                Image(systemName: "person.crop.circle.fill.badge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            default:
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
