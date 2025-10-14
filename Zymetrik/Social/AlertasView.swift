import SwiftUI
import Supabase

// MARK: - ViewModel

@MainActor
final class AlertasViewModel: ObservableObject {
    @Published var items: [AppNotification] = []
    @Published var loading = false
    @Published var error: String?
    
    private var pollTask: Task<Void, Never>?
    private var isActive = false
    
    func load(initial: Bool = false) async {
        if initial { loading = true }
        defer { loading = false }
        do {
            let rows = try await NotificacionesService.shared.fetchNotifications(limit: 100)
            self.items = rows
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refresh() async { await load() }
    
    func markAsRead(_ notif: AppNotification) async {
        guard !notif.isRead else { return }
        do {
            try await NotificacionesService.shared.markNotificationRead(notif.id)
            if let idx = items.firstIndex(where: { $0.id == notif.id }) {
                let n = items[idx]
                items[idx] = AppNotification(
                    id: n.id,
                    type: n.type,
                    actor: n.actor,
                    message: n.message,
                    created_at: n.created_at,
                    read_at: Date(),
                    post_id: n.post_id,
                    comment_id: n.comment_id,
                    chat_id: n.chat_id
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markAllRead() async {
        do {
            try await NotificacionesService.shared.markAllNotificationsRead()
            items = items.map { n in
                AppNotification(
                    id: n.id,
                    type: n.type,
                    actor: n.actor,
                    message: n.message,
                    created_at: n.created_at,
                    read_at: Date(),
                    post_id: n.post_id,
                    comment_id: n.comment_id,
                    chat_id: n.chat_id
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func startPolling(interval: TimeInterval = 20) {
        isActive = true
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.isActive {
                await self.load()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    func stopPolling() {
        isActive = false
        pollTask?.cancel()
        pollTask = nil
    }
}

// MARK: - View

struct AlertasView: View {
    @StateObject private var vm = AlertasViewModel()
    @State private var myUserID: UUID?
    
    // Ocultamos DM en la UI
    private var visibleTypes: [NotificationType] {
        NotificationType.allCases.filter { $0 != .dm }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(visibleTypes, id: \.self) { type in
                    let sectionItems = vm.items.filter { $0.type == type }
                    if !sectionItems.isEmpty {
                        Text(type.tituloSeccion)
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(sectionItems) { n in
                            NavigationLink {
                                destinationFor(n)
                                    .task { await vm.markAsRead(n) }
                            } label: {
                                alertaRow(n)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top)
            .refreshable { await vm.refresh() }
        }
        .navigationTitle("Alertas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if vm.items.contains(where: { !$0.isRead }) {
                    Button("Marcar leídas") { Task { await vm.markAllRead() } }
                }
            }
        }
        .task {
            await vm.load(initial: true)
            vm.startPolling(interval: 20)
            myUserID = await SupabaseManager.shared.currentUserUUID()
        }
        .onDisappear { vm.stopPolling() }
        .alert("Error", isPresented: .constant(vm.error != nil), actions: {
            Button("OK") { vm.error = nil }
        }, message: { Text(vm.error ?? "") })
        .hideTabBarScope()
    }
    
    // MARK: - Row UI

    @ViewBuilder
    private func alertaRow(_ n: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            avatar(n.actor.avatar_url, username: n.actor.username)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: n.type.sfSymbol)
                        .foregroundStyle(color(for: n.type))
                        .font(.subheadline)
                    
                    if shouldShowHandle(for: n) {
                        NavigationLink {
                            destinationProfile(for: n.actor)
                        } label: {
                            Text("@\(n.actor.username)")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(n.message)
                        .font(.body)
                        .lineLimit(3)
                }
                
                Text(n.created_at.timeAgoDisplay())
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer(minLength: 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(n.isRead ? Color.clear : Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 4)
    }
    
    // MARK: - Destinos: siempre abrimos el post, con foco opcional en comentario
    @ViewBuilder
    private func destinationFor(_ n: AppNotification) -> some View {
        switch n.type {
        case .like_post:
            if let pid = n.post_id {
                PostDetailView(postID: pid, focusCommentID: nil)
            } else {
                FallbackView(text: "No se encontró el post.")
            }
        case .comment:
            if let pid = n.post_id {
                // Si viene comment_id → enfoca ese comentario, si no, solo el post
                PostDetailView(postID: pid, focusCommentID: n.comment_id)
            } else {
                FallbackView(text: "No se pudo abrir el comentario.")
            }
        case .like_comment:
            if let pid = n.post_id {
                PostDetailView(postID: pid, focusCommentID: n.comment_id)
            } else {
                FallbackView(text: "No se encontró el comentario.")
            }
        case .follow:
            // Para follow abrimos perfil del actor
            destinationProfile(for: n.actor)
        case .reminder:
            RemindersView()
        case .dm:
            // Oculto en visibleTypes, no debería entrar aquí
            FallbackView(text: "DM oculto")
        }
    }
    
    // MARK: - Perfil

    @ViewBuilder
    private func destinationProfile(for actor: NotificationActor) -> some View {
        if idsEqual(actor.id, myUserID) {
            PerfilView()
        } else {
            UserProfileView(username: actor.username)
        }
    }
    
    // MARK: - Helpers

    private func shouldShowHandle(for n: AppNotification) -> Bool {
        let msg = n.message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let handle = "@\(n.actor.username)".lowercased()
        return !msg.contains(handle)
    }
    
    private func avatar(_ url: String?, username: String) -> some View {
        let fallback = "https://api.dicebear.com/7.x/initials/svg?seed=\(username)"
        let u = URL(string: (url?.isEmpty == false ? url! : fallback))
        return AsyncImage(url: u) { img in
            img.resizable()
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.3))
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }
    
    private func color(for type: NotificationType) -> Color {
        switch type {
        case .follow:       return .blue
        case .like_post:    return .red
        case .like_comment: return .pink
        case .comment:      return .orange
        case .dm:           return .purple
        case .reminder:     return .teal
        }
    }
    
    private func idsEqual(_ a: UUID?, _ b: UUID?) -> Bool {
        guard let a, let b else { return false }
        return a == b
    }
}

// ====== Placeholders: sustituye por tus vistas reales ======

private struct RemindersView: View {
    var body: some View {
        Text("Recordatorios")
            .navigationTitle("Recordatorios")
    }
}

private struct FallbackView: View {
    let text: String
    var body: some View {
        Text(text).foregroundStyle(.secondary).padding()
    }
}
