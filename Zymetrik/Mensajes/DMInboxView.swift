import SwiftUI

// Activa el conteo exacto de no leídos usando el RPC get_dm_unread_count.
// Si es false, usa el cálculo rápido (booleano) comparando last_read_at vs último mensaje.
private let USE_EXACT_UNREAD_COUNT = true

struct DMInboxView: View {
    @EnvironmentObject private var uiState: AppUIState

    @State private var items: [DMInboxItem] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var pushChat: DMInboxItem?
    @State private var showingSearch = false
    @State private var searchText = ""

    @State private var loadTask: Task<Void, Never>? = nil
    @State private var mutatingIDs = Set<UUID>() // bloqueo UI al silenciar/eliminar

    // Filtrado:
    // - texto
    // - oculta conversaciones sin mensajes (lastAt == nil)
    private var filteredItems: [DMInboxItem] {
        let base = items.filter { $0.lastAt != nil } // oculta vacías
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.otherPerfil?.username.localizedCaseInsensitiveContains(searchText) == true ||
            $0.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading { loadingView }
                else if let errorText { errorView(errorText) }
                else if filteredItems.isEmpty { emptyStateView }
                else { conversationsList }
            }
            .navigationTitle("Mensajes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { withAnimation { showingSearch.toggle() } } label: {
                        Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .medium))
                    }
                    NavigationLink {
                        DMNewChatView { convID, user in
                            // No se mostrará hasta que haya 1er mensaje (lastAt nil)
                            let temp = DMInboxItem(
                                id: convID,
                                conversation: .init(id: convID, is_group: false, created_at: Date(), last_message_at: nil),
                                otherPerfil: user,
                                lastMessagePreview: nil,
                                lastAt: nil,
                                unreadCount: 0,
                                isOnline: false,
                                isMuted: false
                            )
                            pushChat = temp
                            loadTask?.cancel()
                            loadTask = Task { await load(isRefresh: false) }
                        }
                        .environmentObject(uiState)
                        .hideTabBarScope()
                    } label: {
                        Image(systemName: "square.and.pencil").font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $showingSearch,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar conversaciones..."
            )
            .task {
                loadTask?.cancel()
                loadTask = Task { await load(isRefresh: false) }
            }
            .navigationDestination(item: $pushChat) { item in
                DMChatView(conversationID: item.id, other: item.otherPerfil)
                    .environmentObject(uiState)
                    .hideTabBarScope()
            }
        }
        .hideTabBarScope()
        .onDisappear { loadTask?.cancel(); loadTask = nil }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.1)
            Text("Cargando conversaciones…")
                .font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44)).foregroundStyle(.orange)
            Text(text).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Reintentar") {
                loadTask?.cancel()
                loadTask = Task { await load(isRefresh: false) }
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 22) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56)).foregroundStyle(.blue.opacity(0.65))
            Text("Sin mensajes").font(.title2.weight(.semibold))
            Text("Empieza una conversación desde un perfil o busca nuevos contactos.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            NavigationLink {
                DMNewChatView { convID, user in
                    pushChat = DMInboxItem(
                        id: convID,
                        conversation: .init(id: convID, is_group: false, created_at: Date(), last_message_at: nil),
                        otherPerfil: user,
                        lastMessagePreview: nil,
                        lastAt: nil
                    )
                    loadTask?.cancel()
                    loadTask = Task { await load(isRefresh: false) }
                }
                .environmentObject(uiState)
                .hideTabBarScope()
            } label: {
                Text("Nuevo mensaje").padding(.horizontal, 24).padding(.vertical, 12)
            }
            .buttonStyle(PrimaryCapsuleButtonStyle())
        }
        .padding(.top, 24)
    }

    private var conversationsList: some View {
        List {
            ForEach(filteredItems) { item in
                ConversationRow(item: item) { open(item) }
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    // Eliminar (trailing)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await deleteConversation(item) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .disabled(mutatingIDs.contains(item.id))
                    }
                    // Silenciar (leading)
                    .swipeActions(edge: .leading) {
                        let muted = item.isMuted
                        Button {
                            Task { await toggleMute(item, to: !muted) }
                        } label: {
                            Label(muted ? "Activar sonido" : "Silenciar",
                                  systemImage: muted ? "bell" : "bell.slash")
                        }
                        .tint(muted ? .blue : .orange)
                        .disabled(mutatingIDs.contains(item.id))
                    }
            }
        }
        .listStyle(.plain)
        .contentMargins(.vertical, 8)
        .refreshable { await load(isRefresh: true) }
        .animation(.easeInOut(duration: 0.2), value: filteredItems)
    }

    // MARK: - Navegación / Leídos

    private func open(_ item: DMInboxItem) {
        // Navegar
        pushChat = item

        // Optimista: limpia el badge en UI
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            var it = items[idx]
            it.unreadCount = 0
            items[idx] = it
        }

        // Marca leído en BD (actualiza dm_members.last_read_at)
        Task {
            await DMMessagingService.shared.markRead(conversationID: item.id)
        }
    }

    // MARK: - Data

    private func load(isRefresh: Bool) async {
        if Task.isCancelled { return }
        await MainActor.run {
            if !isRefresh { loading = true }
            errorText = nil
        }

        do {
            let svc = DMMessagingService.shared
            let myID = try await svc.currentUserID()
            let convs = try await svc.fetchConversations()

            var temp: [DMInboxItem] = []
            temp.reserveCapacity(convs.count)

            try await withThrowingTaskGroup(of: DMInboxItem?.self) { group in
                for conv in convs {
                    group.addTask {
                        if Task.isCancelled { return nil }
                        do {
                            async let members = svc.fetchMembers(conversationID: conv.id)
                            async let lastMsg = svc.fetchLastMessage(conversationID: conv.id)
                            async let muted   = svc.isMuted(conversationID: conv.id)

                            let mems = try await members
                            let last = try? await lastMsg
                            let otherID = mems.first(where: { $0.autor_id != myID })?.autor_id
                            let myRead  = mems.first(where: { $0.autor_id == myID })?.last_read_at
                            let other   = try await (otherID != nil ? svc.fetchPerfil(id: otherID!) : nil)
                            let isMuted = await muted

                            // Cálculo booleano rápido
                            let hasUnreadBool: Bool = {
                                guard let last, let otherID else { return false }
                                if last.autor_id == otherID {
                                    if let myRead { return last.created_at > myRead }
                                    return true
                                }
                                return false
                            }()

                            // ✅ Evita ternario con await
                            let unread: Int
                            if USE_EXACT_UNREAD_COUNT {
                                let exact = await svc.unreadCount(conversationID: conv.id)
                                unread = max(0, exact)
                            } else {
                                unread = hasUnreadBool ? 1 : 0
                            }

                            return DMInboxItem(
                                id: conv.id,
                                conversation: conv,
                                otherPerfil: other,
                                lastMessagePreview: last?.content,
                                lastAt: conv.last_message_at ?? last?.created_at,
                                unreadCount: unread,
                                isOnline: false,
                                isMuted: isMuted
                            )
                        } catch is CancellationError {
                            return nil
                        } catch {
                            return nil
                        }
                    }
                }
                for try await it in group {
                    if Task.isCancelled { break }
                    if let it { temp.append(it) }
                }
            }

            if Task.isCancelled { return }

            // Ordena por fecha del último mensaje
            temp.sort { ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast) }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.items = temp
                }
            }

            // Suscripción de inbox
            Task.detached { [ids = temp.map(\.id)] in
                await DMMessagingService.shared.subscribeInbox(
                    conversationIDs: ids,
                    onConversationBumped: { convID in
                        Task { await refreshConversationItem(convID) }
                    }
                )
            }
        } catch is CancellationError {
            // Ignorar
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }

        await MainActor.run { if !isRefresh { loading = false } }
    }

    private func refreshConversationItem(_ convID: UUID) async {
        do {
            let svc = DMMessagingService.shared
            let myID = try await svc.currentUserID()
            async let last = svc.fetchLastMessage(conversationID: convID)
            async let mems = svc.fetchMembers(conversationID: convID)
            async let muted = svc.isMuted(conversationID: convID)

            let lastMsg = try await last
            let members = try await mems
            let isMuted = await muted

            let otherID = members.first(where: { $0.autor_id != myID })?.autor_id
            let myRead  = members.first(where: { $0.autor_id == myID })?.last_read_at

            let hasUnreadBool: Bool = {
                guard let lastMsg, let otherID else { return false }
                if lastMsg.autor_id == otherID {
                    if let myRead { return lastMsg.created_at > myRead }
                    return true
                }
                return false
            }()

            // ✅ Sin `async let` para unreadExact; todo lineal con await
            let unread: Int
            if USE_EXACT_UNREAD_COUNT {
                let exact = await svc.unreadCount(conversationID: convID)
                unread = max(0, exact)
            } else {
                unread = hasUnreadBool ? 1 : 0
            }

            await MainActor.run {
                if let idx = items.firstIndex(where: { $0.id == convID }) {
                    var it = items[idx]
                    it.lastMessagePreview = lastMsg?.content ?? it.lastMessagePreview
                    it.lastAt = lastMsg?.created_at ?? it.lastAt
                    it.isMuted = isMuted
                    it.unreadCount = unread
                    items[idx] = it
                    withAnimation(.easeInOut(duration: 0.25)) {
                        items.sort { ($0.lastAt ?? .distantPast) > ($1.lastAt ?? .distantPast) }
                    }
                }
            }
        } catch { /* silent */ }
    }

    // MARK: - Mutar / Eliminar

    private func toggleMute(_ item: DMInboxItem, to newValue: Bool) async {
        _ = await MainActor.run { mutatingIDs.insert(item.id) }
        await DMMessagingService.shared.setMuted(conversationID: item.id, mute: newValue)
        _ = await MainActor.run {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isMuted = newValue
            }
            mutatingIDs.remove(item.id)
        }
    }

    private func deleteConversation(_ item: DMInboxItem) async {
        _ = await MainActor.run { mutatingIDs.insert(item.id) }
        do {
            try await DMMessagingService.shared.deleteConversationForMe(conversationID: item.id)
            _ = await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    items.removeAll { $0.id == item.id }
                }
                mutatingIDs.remove(item.id)
            }
        } catch {
            _ = await MainActor.run {
                errorText = error.localizedDescription
                mutatingIDs.remove(item.id)
            }
        }
    }
}
