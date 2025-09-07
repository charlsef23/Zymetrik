import SwiftUI

struct InicioView: View {
    @State private var posts: [Post] = []
    @State private var seleccion = "Para ti"
    @State private var cargando = true

    // Paginación
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    @State private var beforeCursor: Date? = nil

    // Cancela cargas anteriores al cambiar pestaña
    @State private var loadTask: Task<Void, Never>? = nil

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
                                            Task { await loadMore() }
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
            .task { await initialLoad() }
        }
    }

    // MARK: - Carga
    private func initialLoad() async {
        if posts.isEmpty { await refresh() }
    }

    private func restartFeed() {
        loadTask?.cancel()
        loadTask = Task {
            reachedEnd = false
            beforeCursor = nil
            posts = []
            cargando = true
            await loadMore(reset: true)
            cargando = false
        }
    }

    private func refresh() async {
        reachedEnd = false
        beforeCursor = nil
        await loadMore(reset: true)
    }

    private func loadMore(reset: Bool = false) async {
        guard !isLoadingMore, !reachedEnd else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            // Llama a la RPC get_feed_posts (keyset)
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
                p_after_ts: nil, // podrías usarlo para “live updates” (nuevos)
                p_before_ts: beforeCursor.map { iso.string(from: $0) },
                p_limit: 20
            )

            let res = try await SupabaseManager.shared.client
                .rpc("get_feed_posts", params: p)
                .execute()

            let page = try res.decodedList(to: Post.self)

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
        } catch {
            if (error as? CancellationError) == nil {
                print("Error al cargar feed: \(error)")
            }
        }
        cargando = false
    }
}
