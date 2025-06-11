import SwiftUI

struct SocialFeedView: View {
    @State private var selectedTab = "Para ti"
    let tabs = ["Para ti", "Siguiendo"]

    @State private var mostrarFormularioPost = false
    @State private var posts: [EntrenamientoPost] = []
    @State private var followingPosts: [EntrenamientoPost] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Título y acciones
                HStack {
                    Text("Inicio")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: 16) {
                        NavigationLink(destination: AlertasView()) {
                            Image(systemName: "bell.fill")
                        }
                        NavigationLink(destination: MensajesView()) {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Tabs
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(tab)
                                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                                    .foregroundColor(selectedTab == tab ? .black : .gray)
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(selectedTab == tab ? .black : .clear)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Feed
                ScrollView {
                    if (selectedTab == "Para ti" ? posts.isEmpty : followingPosts.isEmpty) {
                        VStack(spacing: 16) {
                            Image(systemName: "bolt.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("Aún no hay publicaciones")
                                .font(.headline)
                                .foregroundColor(.gray)
                            if selectedTab == "Para ti" {
                                Text("Sigue a otros usuarios para ver sus logros.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                            } else {
                                Text("Comparte tu primer entrenamiento 💪")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            Button(action: {
                                mostrarFormularioPost = true
                            }) {
                                Text("Crear publicación")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(selectedTab == "Para ti" ? posts : followingPosts) { post in
                                PostView(post: post)
                            }
                        }
                        .padding(.top)
                        .transition(.opacity)
                    }
                }
            }
            .sheet(isPresented: $mostrarFormularioPost) {
                CrearPostView { nuevo in
                    if selectedTab == "Para ti" {
                        posts.insert(nuevo, at: 0)
                    } else {
                        followingPosts.insert(nuevo, at: 0)
                    }
                }
            }
        }
    }
}
