import SwiftUI

struct InicioView: View {
    @State private var posts: [Post] = []
    @State private var cargando = true
    @State private var errorMsg: String? = nil

    // Paginación
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    @State private var beforeCursor: Date? = nil
    @State private var lastRequestedCursor: Date? = nil

    // Concurrencia
    @State private var loadTask: Task<Void, Never>? = nil
    @State private var feedGeneration: Int = 0   // invalida respuestas viejas

    enum FeedSelection: String, CaseIterable, Identifiable {
        case paraTi = "Para ti"
        case siguiendo = "Siguiendo"
        var id: String { rawValue }
    }
    @State private var selectedFeed: FeedSelection = .paraTi

    private var isParaTi: Bool { selectedFeed == .paraTi }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let errorMsg {
                    Text(errorMsg)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

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
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: selectedFeed) { _, _ in
                restartFeed()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Feed", selection: $selectedFeed) {
                            ForEach(FeedSelection.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedFeed.rawValue)
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        NavigationLink(destination: AlertasView()) { Image(systemName: "bell.fill") }
                        NavigationLink(destination: DMInboxView()) { Image(systemName: "paperplane.fill") }
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .task {
                if posts.isEmpty {
                    await initialSafeLoad()
                }
            }
        }
    }

    // MARK: - Carga inicial defensiva
    private func initialSafeLoad() async {
        await MainActor.run {
            cargando = true
            errorMsg = nil
        }
        do {
            // Precarga segura (tu método existente) para no dejar pantalla vacía
            posts = try await SupabaseService.shared.fetchPosts()
            await MainActor.run { cargando = false }
            // Y arrancamos la paginación real según el feed
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
        loadTask?.cancel()
        feedGeneration &+= 1

        reachedEnd = false
        beforeCursor = nil
        lastRequestedCursor = nil
        cargando = posts.isEmpty
        errorMsg = nil

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

    // MARK: - Carga (único punto de red; ramifica por feed)
    private func loadMore(reset: Bool, generation: Int) async {
        await MainActor.run {
            if isLoadingMore || reachedEnd { return }
            isLoadingMore = true
        }
        defer { Task { @MainActor in isLoadingMore = false } }

        do {
            try Task.checkCancellation()
            guard generation == feedGeneration else { return }

            let me = try await DMMessagingService.shared.currentUserID()

            let page: [Post]
            if isParaTi {
                // === PARA TI: posts de TODO el mundo (tu RPC existente) ===
                struct Params: Encodable {
                    let p_user: UUID
                    let p_after_ts: String?
                    let p_before_ts: String?
                    let p_limit: Int
                }
                let iso = ISO8601DateFormatter()
                let params = Params(
                    p_user: me,
                    p_after_ts: nil,
                    p_before_ts: beforeCursor.map { iso.string(from: $0) },
                    p_limit: 20
                )
                let res = try await SupabaseManager.shared.client
                    .rpc("get_feed_posts", params: params)
                    .execute()
                page = try res.decodedList(to: Post.self)
            } else {
                // === SIGUIENDO: solo autores seguidos (sin RPC nueva) ===
                page = try await SupabaseService.shared.fetchFollowingPosts(
                    userID: me,
                    before: beforeCursor,
                    limit: 20
                )
            }

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
                    beforeCursor = page.last?.fecha // keyset por fecha
                }
            }
        } catch is CancellationError {
            return
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            return
        } catch {
            print("Error al cargar feed:", error)
            await MainActor.run {
                if posts.isEmpty {
                    errorMsg = "No se pudo cargar el feed \(selectedFeed.rawValue): \(error.localizedDescription)"
                }
            }
        }
    }
}
