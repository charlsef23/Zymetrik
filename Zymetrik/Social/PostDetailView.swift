import SwiftUI

struct PostDetailView: View {
    @EnvironmentObject private var uiState: AppUIState

    let postID: UUID
    let focusCommentID: UUID?

    @State private var post: Post? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if let post {
                PostView(post: post)
                    .onAppear {
                        // If we want to focus a specific comment, open comments sheet.
                        if focusCommentID != nil {
                            // PostView exposes a sheet via state, but we can't access it directly here.
                            // As a simple approach, present ComentariosView when focusCommentID is provided.
                        }
                    }
                    .hideTabBarScope()
            } else if isLoading {
                ProgressView("Cargando post…")
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Text("No se pudo cargar el post")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle("Post")
        .task {
            await loadPost()
        }
        .toolbar(.hidden, for: .tabBar)
    }

    @MainActor
    private func loadPost() async {
        isLoading = true
        errorMessage = nil
        do {
            // Fetch a single post by id
            let posts = try await SupabaseService.shared.fetchPosts(id: postID, limit: 1)
            if let first = posts.first {
                self.post = first
            } else {
                self.errorMessage = "El post no existe o fue eliminado."
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

