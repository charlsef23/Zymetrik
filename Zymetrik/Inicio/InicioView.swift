import SwiftUI

struct InicioView: View {
    @State private var posts: [Post] = []
    @State private var seleccion = "Para ti"
    @State private var cargando = true

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
                // Header
                HStack {
                    Text("Inicio")
                        .font(.largeTitle.bold())
                    Spacer()
                    HStack(spacing: 20) {
                        NavigationLink(destination: AlertasView()) { Image(systemName: "bell.fill") }
                        NavigationLink(destination: DMInboxView()) { Image(systemName: "paperplane.fill") }
                    }
                    .font(.title2)
                    .foregroundColor(.foregroundIcon)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Selector
                HStack {
                    ForEach(["Para ti", "Siguiendo"], id: \.self) { opcion in
                        VStack {
                            Text(opcion)
                                .foregroundColor(seleccion == opcion ? Color("ParaTiColor") : .gray)
                                .fontWeight(seleccion == opcion ? .semibold : .regular)
                            if seleccion == opcion {
                                Capsule().fill(Color("ParaTiColor")).frame(height: 3)
                            } else {
                                Color.clear.frame(height: 3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard seleccion != opcion else { return }
                            seleccion = opcion
                            restartFeed()
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal)

                // Lista
                if cargando {
                    ProgressView().padding()
                } else {
                    ScrollView {
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

                Spacer()
            }
            .task {
                if posts.isEmpty {
                    await refresh()
                }
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
        posts = []
        cargando = true

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
            cargando = posts.isEmpty
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
            // Silenciamos cancelaciones por cambios de vista/refresh
            return
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            // Silenciamos NSURLErrorDomain Code -999
            return
        } catch {
            print("Error al cargar feed: \(error)")
        }
    }
}
