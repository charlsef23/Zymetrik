import SwiftUI
import UIKit

struct ComentariosView: View {
    let postID: UUID

    @State private var comentarios: [Comentario] = []
    @State private var respuestasByParent: [UUID?: [Comentario]] = [:]
    @State private var respondiendoA: Comentario? = nil

    @State private var nuevoComentario: String = ""
    @FocusState private var inputFocused: Bool
    @State private var sending = false

    @State private var initialLoading = false
    @State private var isLoadingMore = false
    @State private var reachedEnd = false
    @State private var beforeCursor: Date? = nil
    @State private var lastRequestedCursor: Date? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comentarios").font(.headline)
                    Text("\(comentarios.count) en total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if initialLoading || isLoadingMore {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)

            Divider()

            // Lista
            ScrollViewReader { _ in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if initialLoading {
                            ForEach(0..<6, id: \.self) { _ in
                                CommentSkeleton().padding(.horizontal)
                            }
                        } else {
                            ForEach(respuestasByParent[nil] ?? []) { c in
                                CommentThreadNode(
                                    comentario: c,
                                    nivel: 0,
                                    childrenProvider: { respuestasByParent[$0] ?? [] },
                                    onReply: { handleReply(to: $0) }
                                )
                                .padding(.horizontal)
                            }
                            if !reachedEnd {
                                BottomSentinel { triggerLoadMoreIfNeeded() }
                                    .frame(height: 1)
                                    .padding(.horizontal)
                            } else {
                                HStack {
                                    Spacer()
                                    Text("No hay más")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(.vertical, 12)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .transaction { $0.disablesAnimations = true }
                }
                .onChange(of: respondiendoA?.id) { _, to in
                    if to != nil {
                        inputFocused = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }

            Divider()

            // Composer
            CommentsComposerBar(
                placeholder: respondiendoA == nil
                    ? "Añade un comentario…"
                    : "Responder a @\(respondiendoA?.username ?? "")…",
                text: $nuevoComentario,
                isSending: sending,
                onSend: { Task { await enviarComentario() } },
                onCancelReply: { respondiendoA = nil },
                showCancelReply: respondiendoA != nil
            )
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
        }
        .onAppear { Task { await initialLoad() } }
        .refreshable { await refresh() }
    }

    // MARK: - Interacciones
    private func handleReply(to comentario: Comentario) { respondiendoA = comentario }

    // MARK: - Carga
    private func initialLoad() async {
        if !comentarios.isEmpty { return }
        initialLoading = true
        await refresh()
        initialLoading = false
    }

    private func refresh() async {
        reachedEnd = false
        beforeCursor = nil
        lastRequestedCursor = nil
        await loadMore(reset: true)
    }

    private func triggerLoadMoreIfNeeded() {
        guard !isLoadingMore, !reachedEnd else { return }
        guard beforeCursor != lastRequestedCursor else { return }
        lastRequestedCursor = beforeCursor
        Task { await loadMore() }
    }

    private func loadMore(reset: Bool = false) async {
        guard !isLoadingMore, !reachedEnd else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            struct P: Encodable {
                let p_post: UUID
                let p_limit: Int
                let p_before: Date?   // 👈 usa Date?, el SDK lo serializa a timestamptz
            }

            let params = P(
                p_post: postID,
                p_limit: 50,
                p_before: beforeCursor   // nil en primera página
            )

            let res = try await SupabaseManager.shared.client
                .rpc("api_get_post_comments", params: params)   // 👈 nuevo nombre
                .execute()

            let page = try res.decodedList(to: Comentario.self)

            if reset {
                comentarios = page
            } else {
                var dict = Dictionary(uniqueKeysWithValues: comentarios.map { ($0.id, $0) })
                for c in page { dict[c.id] = c }
                comentarios = dict.values.sorted { $0.creado_en < $1.creado_en }
            }

            respuestasByParent = Dictionary(grouping: comentarios, by: { $0.comentario_padre_id })

            if page.isEmpty {
                reachedEnd = true
            } else {
                // La RPC devuelve DESC; el más antiguo de la página es el último en DESC,
                // pero para cursor "antes de" nos sirve el último de la página
                beforeCursor = page.last?.creado_en
            }
        } catch is CancellationError {
            return
        } catch let e as URLError where e.code == .cancelled {
            return
        } catch {
            print("❌ Error al cargar comentarios: \(error)")
        }
    }

    // MARK: - Enviar
    private func enviarComentario() async {
        let trimmed = nuevoComentario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !sending else { return }

        sending = true
        defer { sending = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let nuevo = NuevoComentario(
                post_id: postID,
                autor_id: session.user.id,
                contenido: trimmed,
                comentario_padre_id: respondiendoA?.id
            )

            let res = try await SupabaseManager.shared.client
                .from("comentarios")
                .insert(nuevo)
                .select("*, perfil:autor_id(username,avatar_url)") // 👈 trae avatar también
                .single()
                .execute()

            let creado = try res.decoded(to: Comentario.self)
            comentarios.append(creado)
            comentarios.sort { $0.creado_en < $1.creado_en }
            respuestasByParent = Dictionary(grouping: comentarios, by: { $0.comentario_padre_id })

            await MainActor.run {
                nuevoComentario = ""
                respondiendoA = nil
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("❌ Error al enviar comentario: \(error)")
        }
    }
}
