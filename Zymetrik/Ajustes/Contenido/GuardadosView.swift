import SwiftUI

struct GuardadosView: View {
    @State private var posts: [Post] = []
    @State private var cargando = true
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if cargando {
                    ProgressView("Cargando guardados…")
                } else if let errorMsg {
                    VStack(spacing: 12) {
                        Text("Error").font(.headline)
                        Text(errorMsg).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button("Reintentar") { Task { await cargar() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if posts.isEmpty {
                    ContentVacioView(
                        title: "Sin guardados",
                        subtitle: "Cuando guardes un post, aparecerá aquí."
                    )
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: []) {
                            ForEach(posts) { post in
                                // Tarjeta
                                VStack {
                                    PostView(
                                        post: post,
                                        onPostEliminado: { remove(post) },
                                        onGuardadoCambio: { saved in
                                            if !saved { withAnimation { remove(post) } }
                                        }
                                    )
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                                )
                                .shadow(radius: 2, y: 1)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable { await cargar() }
                }
            }
            .navigationTitle("Guardados")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await cargar() }
                    } label: { Image(systemName: "arrow.clockwise") }
                    .disabled(cargando)
                }
            }
            .task { await cargar() }
        }
    }

    @MainActor
    private func cargar() async {
        cargando = true
        errorMsg = nil
        do {
            posts = try await SupabaseService.shared.fetchSavedPosts()
        } catch {
            print("❌ Error cargando guardados: \(error)")
            errorMsg = String(describing: error)
        }
        cargando = false
    }

    private func remove(_ post: Post) {
        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
            posts.remove(at: idx)
        }
    }
}

struct ContentVacioView: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark").font(.system(size: 36, weight: .semibold))
                .padding(.bottom, 4)
            Text(title).font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}
