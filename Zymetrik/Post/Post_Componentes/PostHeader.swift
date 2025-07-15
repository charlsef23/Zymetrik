import SwiftUI

struct PostHeader: View {
    let post: Post
    var onEliminar: (() -> Void)?  // Callback para eliminar

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 36, height: 36)

            NavigationLink(destination: UserProfileView(username: post.username)) {
                Text("@\(post.username)")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
            Text(post.fecha.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.gray)

            Menu {
                Button(role: .destructive) {
                    onEliminar?()
                } label: {
                    Label("Eliminar post", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .padding(.leading, 8)
            }
        }
    }
}
