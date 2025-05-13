import SwiftUI

struct SocialFeedView: View {
    @State private var posts: [Post] = [
        Post(username: "Carlos", content: "Entreno completado: Pecho y tríceps 💪 4 ejercicios · 12 series · 4800 kg", timeAgo: "Hace 2 h", likes: 48, comments: 5),
        Post(username: "Laura", content: "Finalizado el día de pierna: 5 ejercicios 🦵", timeAgo: "Hace 5 h", likes: 35, comments: 3)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Encabezado personalizado
                HStack {
                    Text("Inicio")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    HStack(spacing: 16) {
                        NavigationLink(destination: BuscarView()) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.black)
                        }

                        NavigationLink(destination: MensajesView()) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Lista de posts
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(posts.indices, id: \.self) { index in
                            SocialPostView(
                                post: posts[index],
                                onLike: {
                                    posts[index].likes += 1
                                },
                                onComment: {
                                    // Acción para comentarios
                                }
                            )
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
}
