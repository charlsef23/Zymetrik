import SwiftUI
import UIKit
import Supabase

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

    // ❤️ Estado de likes por comentario
    @State private var likedByMe: Set<UUID> = []            // ids de comentarios con like mío
    @State private var likeCounts: [UUID: Int] = [:]        // comentario_id -> count

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
                                VStack(alignment: .leading, spacing: 6) {
                                    CommentThreadNode(
                                        comentario: c,
                                        nivel: 0,
                                        childrenProvider: { respuestasByParent[$0] ?? [] },
                                        onReply: { handleReply(to: $0) }
                                    )
                                    // Barra de acciones (❤️ + responder)
                                    CommentActionsBar(
                                        liked: likedByMe.contains(c.id),
                                        count: likeCounts[c.id] ?? 0,
                                        onToggleLike: { Task { await toggleCommentLike(c.id) } },
                                        onReply: { handleReply(to: c) }
                                    )
                                }
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
        likedByMe.removeAll()
        likeCounts.removeAll()
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
                let p_before: Date?   // el SDK serializa a timestamptz
            }

            let params = P(
                p_post: postID,
                p_limit: 50,
                p_before: beforeCursor   // nil en primera página
            )

            let res = try await SupabaseManager.shared.client
                .rpc("api_get_post_comments", params: params)
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
                // cursor para la siguiente página
                beforeCursor = page.last?.creado_en
                // 🔁 precargar likes para la página llegada
                await preloadLikes(for: page.map { $0.id })
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
                .select("*, perfil:autor_id(username,avatar_url)")
                .single()
                .execute()

            let creado = try res.decoded(to: Comentario.self)
            comentarios.append(creado)
            comentarios.sort { $0.creado_en < $1.creado_en }
            respuestasByParent = Dictionary(grouping: comentarios, by: { $0.comentario_padre_id })

            // inicia contadores del nuevo comentario
            likeCounts[creado.id] = 0

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

    // MARK: - ❤️ Likes de comentarios (batch + toggle)

    /// Carga likes para un conjunto de comentarios y rellena `likeCounts` y `likedByMe`.
    private func preloadLikes(for commentIDs: [UUID]) async {
        guard !commentIDs.isEmpty else { return }
        let client = SupabaseManager.shared.client

        do {
            let me = try await client.auth.session.user.id

            // Traemos todas las filas de likes para estos comentarios
            struct Row: Decodable { let comentario_id: UUID; let autor_id: UUID }

            // Nota: supabase-swift admite `.in("comentario_id", values: [String])`
            let res = try await client
                .from("comentario_likes")
                .select("comentario_id, autor_id", head: false)
                .in("comentario_id", values: commentIDs.map { $0.uuidString })
                .execute()

            let rows = try res.decodedList(to: Row.self)

            // Recuenta por comentario y detecta si yo di like
            var counts: [UUID: Int] = likeCounts
            var liked = likedByMe

            for id in commentIDs { if counts[id] == nil { counts[id] = 0 } }

            for r in rows {
                counts[r.comentario_id, default: 0] += 1
                if r.autor_id == me { liked.insert(r.comentario_id) }
            }

            await MainActor.run {
                likeCounts.merge(counts) { _, new in new }
                likedByMe = liked
            }
        } catch {
            // silencioso para no spamear
        }
    }

    /// Toggle like optimista para un comentario.
    private func toggleCommentLike(_ commentID: UUID) async {
        let client = SupabaseManager.shared.client

        do {
            let me = try await client.auth.session.user.id
            let iLiked = likedByMe.contains(commentID)

            // Optimista
            await MainActor.run {
                if iLiked {
                    likedByMe.remove(commentID)
                    likeCounts[commentID, default: 1] -= 1
                } else {
                    likedByMe.insert(commentID)
                    likeCounts[commentID, default: 0] += 1
                }
            }

            if iLiked {
                // Quitar like
                _ = try await client
                    .from("comentario_likes")
                    .delete()
                    .eq("comentario_id", value: commentID.uuidString)
                    .eq("autor_id", value: me.uuidString)
                    .execute()
            } else {
                // Dar like (idempotente)
                _ = try await client
                    .from("comentario_likes")
                    .upsert(
                        ["comentario_id": commentID.uuidString, "autor_id": me.uuidString],
                        onConflict: "comentario_id,autor_id"
                    )
                    .execute()
            }
        } catch {
            // revertir optimismo si falló
            await MainActor.run {
                if likedByMe.contains(commentID) {
                    likedByMe.remove(commentID)
                    likeCounts[commentID, default: 1] -= 1
                } else {
                    likedByMe.insert(commentID)
                    likeCounts[commentID, default: 0] += 1
                }
            }
            print("❌ toggleCommentLike error:", error.localizedDescription)
        }
    }
}

// MARK: - Barra de acciones por comentario

private struct CommentActionsBar: View {
    let liked: Bool
    let count: Int
    let onToggleLike: () -> Void
    let onReply: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggleLike) {
                HStack(spacing: 6) {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(liked ? .red : .primary)
                        .symbolEffect(.bounce, value: liked)
                    Text("\(max(0, count))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onReply) {
                HStack(spacing: 6) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Responder")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.leading, 52) // un poco de indent para alinear con avatar del comment
        .padding(.top, 2)
        .foregroundStyle(.secondary)
    }
}
