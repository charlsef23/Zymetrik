import SwiftUI

struct InicioView: View {
    @State private var posts: [Post] = []
    @State private var cargando = true
    @State private var errorMsg: String? = nil   // 👈 para mostrar errores

    // Paginación
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    @State private var beforeCursor: Date? = nil
    @State private var lastRequestedCursor: Date? = nil

    // Concurrencia
    @State private var loadTask: Task<Void, Never>? = nil
    @State private var feedGeneration: Int = 0   // invalida respuestas viejas

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Lista / Estado
                if cargando {
                    ProgressView("Cargando…").padding()
                } else if let errorMsg {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No se pudo cargar el feed")
                            .font(.headline)
                        Text(errorMsg)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await initialSafeLoad() }
                        } label: {
                            Text("Reintentar")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 24)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Inicio")
                                .font(.largeTitle.bold())
                                .padding(.horizontal)
                        }
                        .padding(.top, 12)
                        LazyVStack(spacing: 24) {
                            ForEach(posts) { post in
                                PostView(post: post)
                                    .onAppear {
                                        if post.id == posts.last?.id {
                                            triggerLoadMoreIfNeeded()
                                        }
                                    }
                            }
                            if isLoadingMore { ProgressView().padding(.vertical, 12) }
                        }
                        .padding(.top)
                    }
                    .refreshable { await refresh() }
                }

            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        NavigationLink(destination: AlertasView()) { Image(systemName: "bell.fill") }
                        NavigationLink(destination: DMInboxView()) { Image(systemName: "paperplane.fill") }
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .task {
                // Carga inicial defensiva con try/catch
                if posts.isEmpty {
                    await initialSafeLoad()
                }
            }
        }
    }

    // MARK: - Carga inicial defensiva (usa fetchPosts con try/catch)
    private func initialSafeLoad() async {
        await MainActor.run {
            cargando = true
            errorMsg = nil
        }
        do {
            // 👇 Aquí va exactamente el bloque que me pediste, integrado
            posts = try await SupabaseService.shared.fetchPosts()
            await MainActor.run { cargando = false }
            // Una vez cargado “seguro”, activamos tu pipeline de paginación RPC
            restartFeed()
        } catch {
            await MainActor.run {
                cargando = false
                errorMsg = "No se pudo cargar el feed: \(error.localizedDescription)"
                print("❌ fetchPosts error:", error)
            }
        }
    }

    // MARK: - Acciones

    private func restartFeed() {
        // Invalida cualquier respuesta pendiente
        loadTask?.cancel()
        feedGeneration &+= 1

        reachedEnd = false
        beforeCursor = nil
        lastRequestedCursor = nil
        cargando = posts.isEmpty   // si ya tenemos posts de la carga segura, no mostramos spinner

        let currentGen = feedGeneration
        loadTask = Task { [currentGen] in
            await loadMore(reset: true, generation: currentGen)
            await MainActor.run { cargando = false }
        }
    }

    private func refresh() async {
        loadTask?.cancel()
        feedGeneration &+= 1

        await MainActor.run {
            reachedEnd = false
            beforeCursor = nil
            lastRequestedCursor = nil
            // si ya hay posts, mantenemos la UI; si no, muestra spinner
            cargando = posts.isEmpty
            errorMsg = nil
        }

        let currentGen = feedGeneration
        await loadMore(reset: true, generation: currentGen)
        await MainActor.run { cargando = false }
    }

    private func triggerLoadMoreIfNeeded() {
        guard !isLoadingMore, !reachedEnd else { return }
        guard beforeCursor != lastRequestedCursor else { return } // evita duplicar misma página
        lastRequestedCursor = beforeCursor

        let currentGen = feedGeneration
        loadTask?.cancel()
        loadTask = Task { [currentGen] in
            await loadMore(reset: false, generation: currentGen)
        }
    }

    // MARK: - Carga (único punto de red)
    private func loadMore(reset: Bool, generation: Int) async {
        // Doble guard (estado + generación)
        await MainActor.run {
            if isLoadingMore || reachedEnd { return }
            isLoadingMore = true
        }
        defer {
            Task { @MainActor in isLoadingMore = false }
        }

        do {
            try Task.checkCancellation()
            guard generation == feedGeneration else { return }

            // RPC get_feed_posts (keyset)
            struct P: Encodable {
                let p_user: UUID
                let p_after_ts: String?
                let p_before_ts: String?
                let p_limit: Int
            }
            let iso = ISO8601DateFormatter()
            let me = try await DMMessagingService.shared.currentUserID()

            let p = P(
                p_user: me,
                p_after_ts: nil,
                p_before_ts: beforeCursor.map { iso.string(from: $0) },
                p_limit: 20
            )

            let res = try await SupabaseManager.shared.client
                .rpc("get_feed_posts", params: p)
                .execute()

            let page = try res.decodedList(to: Post.self)

            guard generation == feedGeneration else { return }

            await MainActor.run {
                if reset {
                    posts = page
                } else {
                    var dict = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
                    for p in page { dict[p.id] = p }
                    posts = dict.values.sorted { $0.fecha > $1.fecha }
                }

                if page.isEmpty {
                    reachedEnd = true
                } else {
                    // Keyset por fecha
                    beforeCursor = page.last?.fecha
                }
            }
        } catch is CancellationError {
            return
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            return
        } catch {
            print("Error al cargar feed (RPC): \(error)")
            // Si la RPC falla en una carga inicial, muestra el error si no hay posts
            await MainActor.run {
                if posts.isEmpty {
                    errorMsg = "No se pudo cargar el feed (RPC): \(error.localizedDescription)"
                }
            }
        }
    }
}
