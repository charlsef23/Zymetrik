import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PostView: View {
    let post: Post
    var onPostEliminado: (() -> Void)?
    var onGuardadoCambio: ((Bool) -> Void)? = nil

    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false
    @State private var mostrarConfirmacionEliminar = false
    @State private var mostrarShare = false

    // Animación corazón
    @State private var mostrarLikers = false
    @State private var showHeart = false
    @Namespace private var heartNS

    // Control de carga
    @State private var didPrime = false
    @State private var primeTask: Task<Void, Never>? = nil
    @State private var isReady = false

    // Cachés de imágenes predescargadas
    @State private var avatarImage: UIImage? = nil
    @State private var imageCache: [UUID: UIImage] = [:]

    init(
        post: Post,
        onPostEliminado: (() -> Void)? = nil,
        onGuardadoCambio: ((Bool) -> Void)? = nil
    ) {
        self.post = post
        self.onPostEliminado = onPostEliminado
        self.onGuardadoCambio = onGuardadoCambio
    }

    var body: some View {
        Group {
            if isReady {
                content
                    .transition(.opacity.combined(with: .scale))
            } else {
                PostSkeletonView()
            }
        }
        .onAppear {
            if !didPrime {
                didPrime = true
                ejercicioSeleccionado = post.contenido.first
                primeTask?.cancel()
                primeTask = Task { await primeAll() }
            }
        }
        .onDisappear { primeTask?.cancel() }
    }

    // MARK: - Contenido real
    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            PostHeader(
                post: post,
                onEliminar: { mostrarConfirmacionEliminar = true },
                onCompartir: { mostrarShare = true },
                preloadedAvatar: avatarImage
            )

            if let e = ejercicioSeleccionado {
                EjercicioEstadisticasView(
                    ejercicio: e,
                    comparativaAnterior: nil
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            CarruselEjerciciosView(
                ejercicios: post.contenido,
                ejercicioSeleccionado: $ejercicioSeleccionado,
                preloadedImages: imageCache
            )

            PostActionsView(
                leDioLike: $leDioLike,
                numLikes: $numLikes,
                guardado: $guardado,
                mostrarComentarios: $mostrarComentarios,
                toggleLike: toggleLike,
                toggleSave: toggleSave,
                onShowLikers: { mostrarLikers = true } // 👈 abrir lista
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .overlay {
            if showHeart {
                HeartBurst()
                    .matchedGeometryEffect(id: "heart", in: heartNS)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .gesture(
            TapGesture(count: 2).onEnded {
                Task { await doubleTapLike() }
            }
        )
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $mostrarShare) {
            ShareSheet(items: [shareText()])
        }
        .sheet(isPresented: $mostrarLikers) {                 // 👈 hoja de likers
            LikersListView(postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) { eliminarPost() }
            Button("Cancelar", role: .cancel) {}
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Post de @\(post.username)"))
    }

    // MARK: - Carga total (meta + imágenes)
    private func primeAll() async {
        isReady = false

        // Copias inmutables para no capturar `self` en funciones @Sendable
        let postID = post.id
        let autorID = post.autor_id
        let avatarURL = post.avatar_url.flatMap { URL(string: $0) }
        let ejercicios = post.contenido
        let existingAvatar = self.avatarImage
        let existingCache = self.imageCache

        // Prefetch ya disponible (no concurrente)
        if avatarImage == nil, let preA = await FeedPrefetcher.shared.avatar(for: autorID) {
            avatarImage = preA
        }
        if imageCache.isEmpty, let preI = await FeedPrefetcher.shared.images(for: postID) {
            imageCache = preI
        }

        // Helpers concurrentes, @Sendable y sin capturar self
        @Sendable func loadAvatarImage(url: URL?, existing: UIImage?) async -> UIImage? {
            if let existing { return existing }
            if let url {
                return await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 40, height: 40))
            }
            return nil
        }

        @Sendable func loadThumbs(ejercicios: [EjercicioPostContenido], existing: [UUID: UIImage]) async -> [UUID: UIImage] {
            var dict: [UUID: UIImage] = [:]
            await withTaskGroup(of: (UUID, UIImage?)?.self) { group in
                for e in ejercicios {
                    guard existing[e.id] == nil else { continue }
                    if let s = e.imagen_url, let url = URL(string: s) {
                        group.addTask {
                            let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 120, height: 120))
                            return (e.id, img)
                        }
                    }
                }
                for await pair in group {
                    if let (id, img) = pair, let img { dict[id] = img }
                }
            }
            return dict
        }

        // Lanza en paralelo SOLO imágenes (no lanzables)
        async let avatarTask: UIImage? = loadAvatarImage(url: avatarURL, existing: existingAvatar)
        async let thumbsTask: [UUID: UIImage] = loadThumbs(ejercicios: ejercicios, existing: existingCache)

        // Pide la meta con try/await directo (evita ambigüedad de async let + throws)
        var meta: SupabaseService.PostMetaResponse? = nil
        do {
            meta = try await SupabaseService.shared.fetchPostMeta(postID: postID)
        } catch {
            meta = nil
        }

        // Recoge resultados de imágenes
        let avatar = await avatarTask
        let thumbs = await thumbsTask

        await MainActor.run {
            if let m = meta {
                leDioLike = m.liked
                guardado  = m.saved
                numLikes  = max(0, m.likes_count) // clamp defensivo
            }
            if let avatar { avatarImage = avatar }
            imageCache.merge(thumbs) { old, _ in old }
            withAnimation(.easeOut(duration: 0.18)) { isReady = true }
        }
    }

    private func preloadCarouselImages(for ejercicios: [EjercicioPostContenido], existing: [UUID: UIImage]) async -> [UUID: UIImage] {
        var dict: [UUID: UIImage] = [:]
        await withTaskGroup(of: (UUID, UIImage?)?.self) { group in
            for e in ejercicios {
                guard existing[e.id] == nil else { continue }
                if let s = e.imagen_url, let url = URL(string: s) {
                    group.addTask(priority: .userInitiated) {
                        let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 120, height: 120))
                        return (e.id, img)
                    }
                }
            }
            for await pair in group {
                if let (id, img) = pair, let img { dict[id] = img }
            }
        }
        return dict
    }
}

// MARK: - Lógica UI
private extension PostView {
    func shareText() -> String {
        "Entrenamiento de @\(post.username) • \(post.fecha.timeAgoDisplay())"
    }

    func doubleTapLike() async {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        if !leDioLike {
            await toggleLike()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                showHeart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeOut(duration: 0.25)) { showHeart = false }
            }
        } else {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                showHeart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.25)) { showHeart = false }
            }
        }
    }

    func eliminarPost() {
        Task {
            do {
                try await SupabaseService.shared.eliminarPost(postID: post.id)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onPostEliminado?()
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("❌ Error al eliminar el post: \(error)")
            }
        }
    }

    // ✅ Optimista seguro + clamp (nunca < 0) + rollback simétrico
    func toggleLike() async {
        await MainActor.run {
            leDioLike.toggle()
            numLikes += leDioLike ? 1 : -1
        }

        do {
            let r = try await SupabaseService.shared.toggleLikeRPC(postID: post.id, like: leDioLike)
            await MainActor.run {
                leDioLike = r.liked
                numLikes  = r.likes_count
            }
            if r.liked {
                UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
            }
        } catch {
            print("❌ Error al cambiar like: \(error)")
            await MainActor.run {
                leDioLike.toggle()
                numLikes += leDioLike ? 1 : -1
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    func toggleSave() async {
        await MainActor.run { guardado.toggle() }
        do {
            try await SupabaseService.shared.setSaved(postID: post.id, saved: guardado)
            await MainActor.run { onGuardadoCambio?(guardado) }
            UIImpactFeedbackGenerator().impactOccurred(intensity: 0.4)
        } catch {
            print("❌ Error al cambiar guardado: \(error)")
            await MainActor.run {
                guardado.toggle()
                onGuardadoCambio?(guardado)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
