// MARK: - PostView.swift
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

    // Compartir
    @State private var mostrarShare = false
    @State private var mostrarShareOptions = false
    @State private var shareError: String? = nil

    // Animación corazón
    @State private var mostrarLikers = false
    @State private var showHeart = false
    @Namespace private var heartNS

    // Control de carga
    @State private var didPrime = false
    @State private var primeTask: Task<Void, Never>? = nil
    @State private var isReady = false

    // Cache de avatar para el nuevo sistema
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
            // Header mejorado (username + tiempo en una línea)
            PostHeaderMejorado(
                post: post,
                onEliminar: { mostrarConfirmacionEliminar = true },
                onCompartir: { mostrarShareOptions = true }, // abre opciones
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
                onShowLikers: { mostrarLikers = true }
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
        // Sheets / Alerts
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $mostrarShareOptions) {
            ShareOptionsView(
                onSystemShare: { mostrarShare = true },
                onWhatsApp:    { shareToWhatsApp() },
                onInstagram:   { shareToInstagramStories() }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $mostrarShare) {
            ShareSheet(items: shareItems())
        }
        .sheet(isPresented: $mostrarLikers) {
            LikersListView(postID: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) { eliminarPost() }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("No se pudo compartir", isPresented: .constant(shareError != nil)) {
            Button("OK") { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Post de @\(post.username)"))
    }

    // MARK: - Share helpers

    private func shareText() -> String {
        "Entrenamiento de @\(post.username) • \(post.fecha.timeAgoDisplay())"
    }

    private func shareItems() -> [Any] {
        var items: [Any] = [shareText()]
        if let firstID = post.contenido.first?.id, let img = imageCache[firstID] {
            items.append(img)
        }
        return items
    }

    private func shareToWhatsApp() {
        let text = shareText()
        guard let url = URL(string: "whatsapp://send?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
              UIApplication.shared.canOpenURL(url) else {
            shareError = "Parece que WhatsApp no está instalado."
            return
        }
        UIApplication.shared.open(url)
    }

    private func shareToInstagramStories() {
        guard let urlScheme = URL(string: "instagram-stories://share"),
              UIApplication.shared.canOpenURL(urlScheme) else {
            shareError = "Instagram no está instalado."
            return
        }

        // Usamos la primera imagen del post; si no hay, generamos 1x1 transparente
        let stickerImage: UIImage = {
            if let firstID = post.contenido.first?.id, let img = imageCache[firstID] {
                return img
            } else {
                return UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { _ in }
            }
        }()

        guard let pngData = stickerImage.pngData() else {
            shareError = "No se pudo preparar la imagen para Instagram."
            return
        }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.stickerImage": pngData,
            "com.instagram.sharedSticker.backgroundTopColor": "#1F1F1F",
            "com.instagram.sharedSticker.backgroundBottomColor": "#1F1F1F",
            // "com.instagram.sharedSticker.contentURL": "https://tuapp.example/post/\(post.id.uuidString)"
        ]]

        UIPasteboard.general.setItems(pasteboardItems, options: [
            UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60)
        ])

        UIApplication.shared.open(urlScheme)
    }

    // MARK: - Carga total (meta + imágenes) - Integrado con cache de avatares
    private func primeAll() async {
        isReady = false

        let postID = post.id
        let autorID = post.autor_id
        let avatarURL = post.avatar_url?.validHTTPURL
        let ejercicios = post.contenido
        let existingAvatar = self.avatarImage
        let existingCache = self.imageCache

        // Intentar obtener del cache de avatares primero
        if avatarImage == nil {
            if let cacheKey = post.avatar_url, let cachedAvatar = AvatarCache.shared.getImage(forKey: cacheKey) {
                avatarImage = cachedAvatar
            } else if let preA = await FeedPrefetcher.shared.avatar(for: autorID) {
                avatarImage = preA
                if let avatarURL = post.avatar_url {
                    AvatarCache.shared.setImage(preA, forKey: avatarURL)
                }
            }
        }

        // Prefetch de imágenes del carrusel
        if imageCache.isEmpty, let preI = await FeedPrefetcher.shared.images(for: postID) {
            imageCache = preI
        }

        @Sendable func loadAvatarImage(url: URL?, existing: UIImage?) async -> UIImage? {
            if let existing { return existing }
            if let url {
                let img = await FastImageLoader.downsampledImage(from: url, targetSize: .init(width: 60, height: 60))
                if let img = img {
                    AvatarCache.shared.setImage(img, forKey: url.absoluteString)
                }
                return img
            }
            return nil
        }

        @Sendable func loadThumbs(ejercicios: [EjercicioPostContenido], existing: [UUID: UIImage]) async -> [UUID: UIImage] {
            var dict: [UUID: UIImage] = [:]
            await withTaskGroup(of: (UUID, UIImage?)?.self) { group in
                for e in ejercicios {
                    guard existing[e.id] == nil else { continue }
                    if let s = e.imagen_url, let url = s.validHTTPURL {
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

        async let avatarTask: UIImage? = loadAvatarImage(url: avatarURL, existing: existingAvatar)
        async let thumbsTask: [UUID: UIImage] = loadThumbs(ejercicios: ejercicios, existing: existingCache)

        var meta: SupabaseService.PostMetaResponse? = nil
        do {
            meta = try await SupabaseService.shared.fetchPostMeta(postID: postID)
        } catch {
            meta = nil
        }

        let avatar = await avatarTask
        let thumbs = await thumbsTask

        await MainActor.run {
            if let m = meta {
                leDioLike = m.liked
                guardado  = m.saved
                numLikes  = max(0, m.likes_count)
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
                if let s = e.imagen_url, let url = s.validHTTPURL {
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

// MARK: - PostHeader (username + tiempo a la derecha, sin línea gris)
private struct PostHeaderMejorado: View {
    let post: Post
    let onEliminar: () -> Void
    let onCompartir: () -> Void
    let preloadedAvatar: UIImage?
    
    @State private var showMenuOpciones = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            NavigationLink {
                UserProfileView(username: post.username)
            } label: {
                Group {
                    if let preloadedAvatar = preloadedAvatar {
                        AvatarAsyncImage(
                            url: nil,
                            size: 44,
                            preloaded: preloadedAvatar,
                            showBorder: true,
                            borderColor: .white,
                            borderWidth: 2,
                            enableHaptics: true
                        )
                    } else {
                        AvatarAsyncImage(
                            url: post.avatar_url.validHTTPURL,
                            size: 44,
                            showBorder: true,
                            borderColor: .white,
                            borderWidth: 2,
                            enableHaptics: true
                        )
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Username + • + tiempo (una sola línea)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(post.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(post.fecha.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                showMenuOpciones = true
                HapticManager.shared.lightImpact()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog("Opciones del post", isPresented: $showMenuOpciones) {
            Button("Compartir") { onCompartir() }
            Button("Reportar", role: .destructive) { /* TODO: lógica reporte */ }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

// MARK: - Lógica UI
private extension PostView {
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
                HapticManager.shared.mediumImpact()
            }
        } catch {
            print("❌ Error al cambiar like: \(error)")
            await MainActor.run {
                leDioLike.toggle()
                numLikes += leDioLike ? 1 : -1
            }
            HapticManager.shared.error()
        }
    }

    func toggleSave() async {
        await MainActor.run { guardado.toggle() }
        do {
            try await SupabaseService.shared.setSaved(postID: post.id, saved: guardado)
            await MainActor.run { onGuardadoCambio?(guardado) }
            HapticManager.shared.lightImpact()
        } catch {
            print("❌ Error al cambiar guardado: \(error)")
            await MainActor.run {
                guardado.toggle()
                onGuardadoCambio?(guardado)
            }
            HapticManager.shared.error()
        }
    }
}
