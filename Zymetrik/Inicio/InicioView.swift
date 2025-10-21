import SwiftUI

// MARK: - Params del RPC con nulls explícitos
private struct FeedParams: Encodable {
    let p_after_ts: String?     // ISO 8601 o nil
    let p_before_ts: String?    // ISO 8601 o nil
    let p_limit: Int
    let p_user: UUID

    enum CodingKeys: String, CodingKey { case p_after_ts, p_before_ts, p_limit, p_user }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let v = p_after_ts  { try c.encode(v, forKey: .p_after_ts) }  else { try c.encodeNil(forKey: .p_after_ts) }
        if let v = p_before_ts { try c.encode(v, forKey: .p_before_ts) } else { try c.encodeNil(forKey: .p_before_ts) }
        try c.encode(p_limit, forKey: .p_limit)
        try c.encode(p_user, forKey: .p_user)
    }
}

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
    @State private var feedGeneration: Int = 0

    enum FeedSelection: String, CaseIterable, Identifiable {
        case paraTi = "Para ti"
        case siguiendo = "Siguiendo"
        var id: String { rawValue }
    }
    @State private var selectedFeed: FeedSelection = .paraTi
    private var isParaTi: Bool { selectedFeed == .paraTi }

    // Formatter ISO con fracciones y UTC para el RPC
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

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
                            PostView(post: post, feedKey: selectedFeed)
                                .id("\(selectedFeed.rawValue)-\(post.id)") // identidad por feed
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
            .onChange(of: selectedFeed) { _, _ in restartFeed() }
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
                            Text(selectedFeed.rawValue).font(.headline)
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
            posts = try await SupabaseService.shared.fetchPosts()
            await MainActor.run { cargando = false }
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
        guard beforeCursor != lastRequestedCursor else { return }
        lastRequestedCursor = beforeCursor

        let currentGen = feedGeneration
        loadTask?.cancel()
        loadTask = Task { [currentGen] in
            await loadMore(reset: false, generation: currentGen)
        }
    }

    // MARK: - Carga paginada
    private func loadMore(reset: Bool, generation: Int) async {
        await MainActor.run {
            if isLoadingMore || reachedEnd { return }
            isLoadingMore = true
        }
        defer { Task { @MainActor in isLoadingMore = false } }

        do {
            try Task.checkCancellation()
            guard generation == feedGeneration else { return }

            let me = try await DMMessagingService.shared.currentUserID() // UUID

            let page: [Post]
            if isParaTi {
                // RPC con nulls explícitos para evitar PGRST202
                let params = FeedParams(
                    p_after_ts: nil,
                    p_before_ts: beforeCursor.map { iso.string(from: $0) },
                    p_limit: 20,
                    p_user: me
                )

                let res = try await SupabaseManager.shared.client
                    .rpc("get_feed_posts", params: params)
                    .execute()

                page = try res.decodedList(to: Post.self)
            } else {
                // Feed "Siguiendo"
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
                    beforeCursor = page.last?.fecha
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
