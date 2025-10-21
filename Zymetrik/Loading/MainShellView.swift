import SwiftUI

struct MainShellView: View {
    @EnvironmentObject var content: ContentStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header simple
                HStack {
                    Text("Inicio").font(.largeTitle.bold())
                    Spacer()
                    NavigationLink(destination: AlertasView()) { Image(systemName: "bell.fill") }
                    NavigationLink(destination: DMInboxView()) { Image(systemName: "paperplane.fill") }
                }
                .font(.title2)
                .padding(.horizontal)
                .padding(.top, 20)

                // Lista de posts
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(content.posts) { post in
                            // 👇 Añadido feedKey
                            PostView(post: post, feedKey: .paraTi)
                        }
                    }
                    .padding(.top)
                }
                .refreshable {
                    await content.reloadFeed()
                }
            }
        }
    }
}
