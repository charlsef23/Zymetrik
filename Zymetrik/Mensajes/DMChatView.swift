import SwiftUI

struct DMChatView: View {
    let conversationID: UUID
    let other: PerfilLite?

    @State private var messages: [DMMessage] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var composing: String = ""

    @State private var myID: UUID?
    @State private var otherID: UUID?
    @State private var myLastReadAt: Date?
    @State private var otherLastReadAt: Date?

    @State private var isTypingOther = false
    @State private var firstUnreadAnchor: UUID?

    @State private var showProfile = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                RefreshableScrollView(topRefresh: { await loadMore() }) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if loading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        } else if let errorText {
                            Text(errorText).foregroundColor(.secondary).padding(.vertical, 8)
                        }

                        ForEach(messages, id: \.id) { msg in
                            MessageBubble(
                                message: msg,
                                isMine: msg.autor_id == myID,
                                seenByOther: seenByOther(msg),
                                onEdit: { newText in Task { await edit(msg, newText: newText) } },
                                onDeleteForAll: { Task { await deleteForAll(msg) } },
                                onDeleteForMe: { Task { await deleteForMe(msg) } }
                            )
                            .id(msg.id)
                            .padding(.horizontal, 12)
                        }

                        Color.clear.frame(height: 8).id("BOTTOM_ANCHOR")
                    }
                    .padding(.top, 6)
                    .onChange(of: messages) { _, _ in
                        if let anchor = firstUnreadAnchor {
                            withAnimation { proxy.scrollTo(anchor, anchor: .center) }
                            firstUnreadAnchor = nil
                        } else {
                            withAnimation { proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom) }
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let anchor = firstUnreadAnchor {
                            proxy.scrollTo(anchor, anchor: .center)
                            firstUnreadAnchor = nil
                        } else {
                            proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                        }
                    }
                }
            }

            ComposerBar(text: $composing, onSend: { Task { await send() } })
                .onChange(of: composing) { _, newValue in
                    Task { await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: !newValue.isEmpty) }
                }
        }
        .toolbar {
            // Botón de retroceso (solo flecha)
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    Button {
                        // Acción de volver atrás
                        // Si usas NavigationStack:
                        // Usa dismiss() del Environment
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    // 👇 Tu topbar al lado de la flecha
                    ChatTopBar(user: other, isTyping: isTypingOther) {
                        showProfile = true
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true) // 👈 ocultamos el botón por defecto
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar) // header translúcido
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 6) }
        .task { await initialLoadAndSubscribe() }
        .onDisappear {
            Task {
                await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: false)
                await DMMessagingService.shared.unsubscribe(conversationID: conversationID)
            }
        }
        .navigationDestination(isPresented: $showProfile) {
            if let other {
                UserProfileView(username: other.username)
                // Si tu init real es por id, usa:
                // UserProfileView(userId: other.id)
            } else {
                Text("Perfil no disponible").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Load + Realtime
    private func initialLoadAndSubscribe() async {
        loading = true; errorText = nil
        do {
            myID = try? await DMMessagingService.shared.currentUserID()

            let members = try await DMMessagingService.shared.fetchMembers(conversationID: conversationID)
            let my = myID
            otherID = members.first(where: { $0.autor_id != my })?.autor_id
            myLastReadAt = members.first(where: { $0.autor_id == my })?.last_read_at
            otherLastReadAt = members.first(where: { $0.autor_id == otherID })?.last_read_at
            isTypingOther = (members.first(where: { $0.autor_id == otherID })?.is_typing) ?? false

            let fresh = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, pageSize: 50)
            messages = fresh

            if let cut = myLastReadAt {
                firstUnreadAnchor = messages.first(where: { $0.created_at > cut })?.id
            } else {
                firstUnreadAnchor = messages.last?.id
            }

            await DMMessagingService.shared.markRead(conversationID: conversationID)

            _ = await DMMessagingService.shared.subscribe(
                conversationID: conversationID,
                handlers: .init(
                    onInserted: { msg in
                        DispatchQueue.main.async { appendIfNew(msg) }
                    },
                    onUpdated: { msg in
                        DispatchQueue.main.async { upsert([msg]) }
                    },
                    onDeletedGlobal: { msgID in
                        DispatchQueue.main.async { messages.removeAll { $0.id == msgID } }
                    },
                    onTypingChanged: { uid, typing in
                        guard uid == otherID else { return }
                        DispatchQueue.main.async { isTypingOther = typing }
                    },
                    onMembersUpdated: { mems in
                        DispatchQueue.main.async {
                            myLastReadAt = mems.first(where: { $0.autor_id == myID })?.last_read_at
                            otherLastReadAt = mems.first(where: { $0.autor_id == otherID })?.last_read_at
                        }
                    }
                )
            )
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func loadMore() async {
        guard let oldest = messages.first?.created_at else { return }
        do {
            let more = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, before: oldest, pageSize: 50)
            upsert(more)
        } catch {
            errorText = error.localizedDescription
        }
    }

    // MARK: - Actions
    private func send() async {
        let text = composing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let myID else { return }

        let tag = UUID().uuidString
        let local = DMMessage(
            id: UUID(),
            conversation_id: conversationID,
            autor_id: myID,
            content: text,
            created_at: Date(),
            client_tag: tag,
            edited_at: nil,
            deleted_for_all_at: nil,
            _delivery: .pending
        )
        appendIfNew(local)
        composing = ""

        do {
            let confirmed = try await DMMessagingService.shared.sendMessage(conversationID: conversationID, text: text, clientTag: tag)
            if let idx = messages.firstIndex(where: { $0.client_tag == tag }) {
                messages[idx] = confirmed
                messages[idx]._delivery = .sent
            } else {
                appendIfNew(confirmed)
            }
            await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: false)
            await DMMessagingService.shared.markRead(conversationID: conversationID)
        } catch {
            if let idx = messages.firstIndex(where: { $0.client_tag == tag }) {
                messages[idx]._delivery = .failed
            }
            composing = text
        }
    }

    private func edit(_ msg: DMMessage, newText: String) async {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let updated = try await DMMessagingService.shared.editMessage(messageID: msg.id, newText: trimmed)
            upsert([updated])
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func deleteForAll(_ msg: DMMessage) async {
        do {
            _ = try await DMMessagingService.shared.deleteMessageForAll(messageID: msg.id)
            messages.removeAll { $0.id == msg.id }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func deleteForMe(_ msg: DMMessage) async {
        await DMMessagingService.shared.hideMessageForMe(conversationID: conversationID, messageID: msg.id)
        messages.removeAll { $0.id == msg.id }
    }

    // MARK: - Helpers
    private func seenByOther(_ msg: DMMessage) -> Bool {
        guard msg.autor_id == myID, let otherRead = otherLastReadAt else { return false }
        return otherRead >= msg.created_at
    }

    private func upsert(_ newMessages: [DMMessage]) {
        var byId = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        for m in newMessages { byId[m.id] = m }
        messages = byId.values
            .filter { $0.deleted_for_all_at == nil }
            .sorted { $0.created_at < $1.created_at }
    }

    private func appendIfNew(_ m: DMMessage) {
        guard !messages.contains(where: { $0.id == m.id }) else { return }
        messages.append(m)
        messages.sort { $0.created_at < $1.created_at }
    }
}
