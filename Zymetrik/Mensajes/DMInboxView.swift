import SwiftUI

struct DMInboxItem: Identifiable, Hashable {
    let id: UUID
    let conversation: DMConversation
    let otherPerfil: PerfilLite?
    var lastMessagePreview: String?
    var lastAt: Date?
    var unreadCount: Int = 0
    var isOnline: Bool = false
}

struct DMInboxView: View {
    @EnvironmentObject private var uiState: AppUIState

    @State private var items: [DMInboxItem] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var pushChat: DMInboxItem?
    @State private var showingSearch = false
    @State private var searchText = ""

    var filteredItems: [DMInboxItem] {
        if searchText.isEmpty { return items }
        return items.filter { item in
            item.otherPerfil?.username.localizedCaseInsensitiveContains(searchText) == true ||
            item.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Group {
                    if loading {
                        loadingView
                    } else if let errorText {
                        errorView(errorText)
                    } else if items.isEmpty {
                        emptyStateView
                    } else {
                        conversationsList
                    }
                }
            }
            .navigationTitle("Mensajes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSearch.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                    }

                    NavigationLink(
                        destination:
                            DMNewChatView(onCreated: { convID, user in
                                let temp = DMInboxItem(
                                    id: convID,
                                    conversation: DMConversation(
                                        id: convID,
                                        is_group: false,
                                        created_at: Date(),
                                        last_message_at: nil
                                    ),
                                    otherPerfil: user,
                                    lastMessagePreview: nil,
                                    lastAt: nil
                                )
                                pushChat = temp
                                Task { await load() }
                            })
                            .environmentObject(uiState)   // opcional (hereda del árbol)
                            .hideTabBarScope()            // ocultar también en NewChat
                    ) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $showingSearch,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar conversaciones..."
            )
            .task { await load() }
            .navigationDestination(item: $pushChat) { item in
                DMChatView(conversationID: item.id, other: item.otherPerfil)
                    .environmentObject(uiState)  // opcional (hereda del árbol)
                    .hideTabBarScope()           // ocultar en Chat
            }
        }
        // ⬇️ Inbox también oculta la barra (sin tocar la propiedad directamente)
        .hideTabBarScope()
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("Cargando conversaciones...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ errorText: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Error").font(.headline)
                Text(errorText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await load() }
            } label: {
                Text("Reintentar")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.6))

            VStack(spacing: 8) {
                Text("Sin mensajes").font(.title2.weight(.semibold))
                Text("Empieza una conversación desde un perfil o busca nuevos contactos.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            NavigationLink(
                destination:
                    DMNewChatView(onCreated: { convID, user in
                        let temp = DMInboxItem(
                            id: convID,
                            conversation: DMConversation(
                                id: convID,
                                is_group: false,
                                created_at: Date(),
                                last_message_at: nil
                            ),
                            otherPerfil: user
                        )
                        pushChat = temp
                        Task { await load() }
                    })
                    .environmentObject(uiState)
                    .hideTabBarScope()
            ) {
                Text("Nuevo mensaje")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private var conversationsList: some View {
        List {
            ForEach(filteredItems) { item in
                ConversationRow(item: item) {
                    pushChat = item
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable { await load() }
    }

    // MARK: - Data Loading
    private func load() async {
        await MainActor.run {
            loading = true
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
                        do {
                            async let members = svc.fetchMembers(conversationID: conv.id)

                            let last: DMMessage?
                            do {
                                last = try await svc.fetchLastMessage(conversationID: conv.id)
                            } catch {
                                let one = try await svc.fetchMessages(conversationID: conv.id, pageSize: 1)
                                last = one.last
                            }

                            let mems = try await members
                            let otherID = mems.map(\.autor_id).first { $0 != myID }
                            let other = try await (otherID != nil ? svc.fetchPerfil(id: otherID!) : nil)

                            return DMInboxItem(
                                id: conv.id,
                                conversation: conv,
                                otherPerfil: other,
                                lastMessagePreview: last?.content,
                                lastAt: conv.last_message_at ?? last?.created_at
                            )
                        } catch {
                            return nil
                        }
                    }
                }
                for try await item in group {
                    if let item { temp.append(item) }
                }
            }

            temp.sort { (a, b) in (a.lastAt ?? .distantPast) > (b.lastAt ?? .distantPast) }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.items = temp
                }
            }

            Task {
                await DMMessagingService.shared.subscribeInbox(
                    conversationIDs: temp.map { $0.id },
                    onConversationBumped: { convID in
                        Task { await refreshConversationItem(convID) }
                    }
                )
            }
        } catch {
            await MainActor.run { self.errorText = error.localizedDescription }
        }

        await MainActor.run { loading = false }
    }

    private func refreshConversationItem(_ convID: UUID) async {
        do {
            let svc = DMMessagingService.shared
            let last = try await svc.fetchLastMessage(conversationID: convID)

            await MainActor.run {
                if let idx = items.firstIndex(where: { $0.id == convID }) {
                    var item = items[idx]
                    item.lastMessagePreview = last?.content ?? item.lastMessagePreview
                    item.lastAt = last?.created_at ?? item.lastAt
                    items[idx] = item

                    withAnimation(.easeInOut(duration: 0.3)) {
                        items.sort { (a, b) in (a.lastAt ?? .distantPast) > (b.lastAt ?? .distantPast) }
                    }
                }
            }
        } catch {
            // silencioso
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let item: DMInboxItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarAsyncImage(
                        url: URL(string: item.otherPerfil?.avatar_url ?? ""),
                        size: 56
                    )

                    if item.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(.background, lineWidth: 3)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.otherPerfil?.username ?? "Conversación")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        if let date = item.lastAt {
                            Text(shortDate(date))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text(item.lastMessagePreview ?? "Toca para escribir...")
                            .font(.system(size: 15))
                            .foregroundStyle(item.lastMessagePreview != nil ? .secondary : .tertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if item.unreadCount > 0 {
                            Text("\(item.unreadCount)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.doesRelativeDateFormatting = true

        if Calendar.current.isDateInToday(date) {
            f.timeStyle = .short
            f.dateStyle = .none
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            f.dateFormat = "EEEE"
        } else {
            f.dateStyle = .short
            f.timeStyle = .none
        }
        return f.string(from: date)
    }
}
