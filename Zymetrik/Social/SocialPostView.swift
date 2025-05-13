import SwiftUI

struct Post: Identifiable {
    let id = UUID()
    let username: String
    let content: String
    let timeAgo: String
    var likes: Int
    var comments: Int
}

struct SocialPostView: View {
    var post: Post
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onSave: () -> Void = {}
    var onShare: () -> Void = {}

    @State private var isLiked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(String(post.username.prefix(1)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(post.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(post.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    Text(post.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action Buttons
            HStack(spacing: 32) {
                Button {
                    onLike()
                    isLiked.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "bolt.fill" : "bolt")
                        Text("\(post.likes)")
                    }
                }
                .foregroundColor(isLiked ? .blue : .gray)

                Button(action: onComment) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }

                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark")
                        Text("Guardar")
                    }
                }

                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir")
                    }
                }

                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.gray)

            Divider()
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

#Preview {
    SocialPostView(post: Post(
        username: "Carlos",
        content: "Entreno completado: Pecho y tríceps 💪 4 ejercicios · 12 series · 4800 kg",
        timeAgo: "Hace 2 h",
        likes: 48,
        comments: 5
    ))
}