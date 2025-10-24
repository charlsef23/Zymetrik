import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PostView: View {
    let post: Post
    let feedKey: InicioView.FeedSelection
    var onPostEliminado: (() -> Void)?
    var onGuardadoCambio: ((Bool) -> Void)? = nil

    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false
    @State private var mostrarConfirmacionEliminar = false
    @State private var isDeleting = false

    // Compartir
    @State private var mostrarShare = false
    @State private var mostrarShareOptions = false
    @State private var shareError: String? = nil

    // Animación corazón
    @State private var mostrarLikers = false
    @State private var showHeart = false
    @Namespace private var heartNS

    // Reportar
    @State private var mostrarReportar = false
    @State private var reportSuccess = false
    @State private var reportErrorMsg: String?

    init(
        post: Post,
        feedKey: InicioView.FeedSelection,
        onPostEliminado: (() -> Void)? = nil,
        onGuardadoCambio: ((Bool) -> Void)? = nil
    ) {
        self.post = post
        self.feedKey = feedKey
        self.onPostEliminado = onPostEliminado
        self.onGuardadoCambio = onGuardadoCambio
    }

    private var isOwnPost: Bool {
        if let session = SupabaseManager.shared.client.auth.currentSession {
            return session.user.id == post.autor_id
        }
        return false
    }

    var body: some View {
        // Siempre muestra el contenido (sin skeleton)
        mainCard
            .onAppear {
                if ejercicioSeleccionado == nil {
                    ejercicioSeleccionado = post.contenido.first
                }
                // Carga meta (like/guardado) sin bloquear UI
                Task { await loadMeta() }
            }
            // iOS 17+: usar onChange con cierre sin parámetros
            .onChange(of: feedKey) {
                ejercicioSeleccionado = post.contenido.first
            }
            .onChange(of: post.id) {
                ejercicioSeleccionado = post.contenido.first
            }
    }

    // MARK: - Subvistas

    private var headerView: some View {
        PostHeaderMejorado(
            post: post,
            isOwnPost: isOwnPost,
            onEliminar: { mostrarConfirmacionEliminar = true },
            onCompartir: { mostrarShareOptions = true },
            preloadedAvatar: nil, // sin avatar precargado
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
        // Pasamos diccionario vacío si la vista lo requiere
        CarruselEjerciciosView(
            ejercicios: post.contenido,
            ejercicioSeleccionado: $ejercicioSeleccionado,
            preloadedImages: [:]
        )
    }

    private var actionsView: some View {
        PostActionsView(
            leDioLike: $leDioLike,
            numLikes: $numLikes,
            guardado: $guardado,
            mostrarComentarios: $mostrarComentarios,
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
            Button(isDeleting ? "Eliminando…" : "Eliminar", role: .destructive) {
                guard !isDeleting else { return }
                eliminarPost()
            }
            .disabled(isDeleting)
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
        [shareText()]
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

        // Si quisieras compartir imagen real, captura snapshot del carrusel aquí
        let emptyImage = UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { _ in }
        guard let pngData = emptyImage.pngData() else {
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

    // MARK: - Acciones

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
            guard !isDeleting else { return }
            isDeleting = true
            defer { isDeleting = false }

            struct Params: Encodable { let p_post_id: String }
            do {
                _ = try await SupabaseManager.shared.client
                    .rpc("delete_post_cascade", params: Params(p_post_id: post.id.uuidString))
                    .execute()

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

    // Carga meta ligera (likes/guardado) con tipo explícito para evitar ambigüedad
    private func loadMeta() async {
        do {
            let m: SupabaseService.PostMetaResponse =
                try await SupabaseService.shared.fetchPostMeta(postID: post.id)
            await MainActor.run {
                leDioLike = m.liked
                guardado  = m.saved
                numLikes  = max(0, m.likes_count)
            }
        } catch {
            // silencioso
        }
    }
}

// MARK: - Header
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

// MARK: - Hoja Reporte
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
