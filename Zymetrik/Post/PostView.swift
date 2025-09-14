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

    // Reportar
    @State private var mostrarReportar = false
    @State private var reportSuccess = false
    @State private var reportErrorMsg: String?

    init(
        post: Post,
        onPostEliminado: (() -> Void)? = nil,
        onGuardadoCambio: ((Bool) -> Void)? = nil
    ) {
        self.post = post
        self.onPostEliminado = onPostEliminado
        self.onGuardadoCambio = onGuardadoCambio
    }

    // ¿Es un post propio?
    private var isOwnPost: Bool {
        if let session = SupabaseManager.shared.client.auth.currentSession {
            return session.user.id == post.autor_id
        }
        return false
    }

    var body: some View {
        Group {
            if isReady {
                mainCard
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

    // MARK: - Subvistas (para ayudar al type-checker)

    private var headerView: some View {
        PostHeaderMejorado(
            post: post,
            isOwnPost: isOwnPost,
            onEliminar: { mostrarConfirmacionEliminar = true },
            onCompartir: { mostrarShareOptions = true },
            preloadedAvatar: avatarImage,
            onReportar: { mostrarReportar = true }
        )
    }

    private var statsView: some View {
        Group {
            if let e = ejercicioSeleccionado {
                EjercicioEstadisticasView(
                    ejercicio: e,
                    comparativaAnterior: nil
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var carouselView: some View {
        CarruselEjerciciosView(
            ejercicios: post.contenido,
            ejercicioSeleccionado: $ejercicioSeleccionado,
            preloadedImages: imageCache
        )
    }

    private var actionsView: some View {
        PostActionsView(
            leDioLike: $leDioLike,
            numLikes: $numLikes,
            guardado: $guardado,
            mostrarComentarios: $mostrarComentarios,
            // Las funciones son async → envolver en Task
            toggleLike: { Task { await self.toggleLike() } },
            toggleSave: { Task { await self.toggleSave() } },
            onShowLikers: { mostrarLikers = true }
        )
    }

    private var heartOverlay: some View {
        Group {
            if showHeart {
                HeartBurst()
                    .matchedGeometryEffect(id: "heart", in: heartNS)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            statsView
            carouselView
            actionsView
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .overlay(heartOverlay)
        .gesture(
            TapGesture(count: 2).onEnded {
                Task { await self.doubleTapLike() }
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
        .sheet(isPresented: $mostrarReportar) {
            ReportPostSheet { reason in
                Task { await reportPost(reason: reason) }
            }
            .presentationDetents([.medium])
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) { self.eliminarPost() }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("Reporte enviado", isPresented: $reportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Gracias por ayudarnos a moderar el contenido.")
        }
        .alert("No se pudo compartir", isPresented: .constant(shareError != nil)) {
            Button("OK") { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
        .alert("No se pudo reportar", isPresented: .constant(reportErrorMsg != nil)) {
            Button("OK") { reportErrorMsg = nil }
        } message: {
            Text(reportErrorMsg ?? "")
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
        ]]

        UIPasteboard.general.setItems(pasteboardItems, options: [
            UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60)
        ])

        UIApplication.shared.open(urlScheme)
    }

    // MARK: - Report helpers

    private func reportPost(reason: String?) async {
        // Params tipados para el RPC
        struct ReportPostParams: Encodable {
            let p_post_id: String
            let p_reason: String?
        }

        do {
            let params = ReportPostParams(
                p_post_id: post.id.uuidString,
                p_reason: (reason?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? reason : nil
            )

            _ = try await SupabaseManager.shared.client
                .rpc("report_post", params: params)
                .execute()

            await MainActor.run { reportSuccess = true }
            HapticManager.shared.success()
        } catch {
            await MainActor.run { reportErrorMsg = error.localizedDescription }
            HapticManager.shared.error()
        }
    }

    // MARK: - Lógica UI / acciones

    private func doubleTapLike() async {
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

    private func eliminarPost() {
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

    private func toggleLike() async {
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

    private func toggleSave() async {
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

    // MARK: - Carga total (meta + imágenes)

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
}

// MARK: - PostHeader (username + tiempo; condicional de eliminar y navegación del username)
private struct PostHeaderMejorado: View {
    let post: Post
    let isOwnPost: Bool
    let onEliminar: () -> Void
    let onCompartir: () -> Void
    let preloadedAvatar: UIImage?
    let onReportar: () -> Void

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

            // Username + tiempo (propio -> PerfilView, otro -> UserProfileView)
            VStack(alignment: .leading, spacing: 0) {
                if isOwnPost {
                    NavigationLink { PerfilView() } label: { usernameAndTime }
                        .buttonStyle(.plain)
                } else {
                    NavigationLink { UserProfileView(username: post.username) } label: { usernameAndTime }
                        .buttonStyle(.plain)
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
            if isOwnPost {
                Button("Eliminar", role: .destructive) { onEliminar() }
            }
            Button("Compartir") { onCompartir() }
            Button("Reportar", role: .destructive) { onReportar() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var usernameAndTime: some View {
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
        .contentShape(Rectangle())
    }
}

// MARK: - Hoja de reportar

private struct ReportPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = ""
    @State private var sending = false
    var onSend: (String?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Cuéntanos brevemente el motivo (opcional).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $reason)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.05))
                    )

                Spacer()
            }
            .padding()
            .navigationTitle("Reportar post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(sending ? "Enviando…" : "Enviar") {
                        guard !sending else { return }
                        sending = true
                        onSend(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reason)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            sending = false
                            dismiss()
                        }
                    }
                    .disabled(sending)
                }
            }
        }
    }
}
