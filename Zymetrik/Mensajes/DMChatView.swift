import SwiftUI

private struct BottomVisibleKey: PreferenceKey {
    static var defaultValue: Bool = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = nextValue() }
}

struct DMChatView: View {
    @EnvironmentObject private var uiState: AppUIState

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
    @State private var isLoadingMore = false

    // Realtime UX
    @State private var isAtBottom: Bool = true
    @State private var showNewMsgPill: Bool = false
    @State private var lastKnownLastID: UUID?
    @State private var hidePillTask: Task<Void, Never>?
    @State private var newIncomingCount: Int = 0

    // Debounce typing
    @State private var typingTask: Task<Void, Never>?

    // Fallback live-polling
    @State private var pollingTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            if loading {
                                HStack { Spacer(); ProgressView(); Spacer() }
                                    .padding(.vertical, 12)
                            } else if let errorText {
                                Text(errorText)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                                    .multilineTextAlignment(.center)
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

                            Color.clear
                                .frame(height: 8)
                                .id("BOTTOM_ANCHOR")
                                .background(
                                    GeometryReader { geo in
                                        let minY = geo.frame(in: .named("chatScroll")).minY
                                        let height = geo.size.height
                                        let visible = minY < 80 + height
                                        Color.clear
                                            .preference(key: BottomVisibleKey.self, value: visible)
                                    }
                                )
                        }
                        .padding(.top, 6)
                    }
                    .coordinateSpace(name: "chatScroll")
                    .refreshable { await loadMore() }
                    .onChange(of: messages) { old, new in
                        let oldLastID = lastKnownLastID
                        let newLastID = new.last?.id
                        defer { lastKnownLastID = newLastID }

                        guard let oldLastID, let myID else {
                            if isAtBottom {
                                withAnimation { proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom) }
                                showNewMsgPill = false
                                newIncomingCount = 0
                            }
                            return
                        }

                        guard let oldIdx = old.firstIndex(where: { $0.id == oldLastID }) ?? old.indices.last else { return }
                        let appended = Array(new.suffix(from: min(new.count, oldIdx + 1)))

                        let mine   = appended.filter { $0.autor_id == myID }
                        let others = appended.filter { $0.autor_id != myID }

                        if isAtBottom {
                            withAnimation { proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom) }
                            showNewMsgPill = false
                            newIncomingCount = 0
                            cancelHidePillTimer()
                        } else {
                            if !others.isEmpty {
                                newIncomingCount += others.count
                                showNewMsgPill = true
                                startHidePillTimer()
                            } else if !mine.isEmpty {
                                newIncomingCount = 1
                                showNewMsgPill = true
                                startHidePillTimer()
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
                    .onPreferenceChange(BottomVisibleKey.self) { atBottom in
                        isAtBottom = atBottom
                        if atBottom {
                            showNewMsgPill = false
                            newIncomingCount = 0
                            cancelHidePillTimer()
                        }
                    }
                }

                ComposerBar(text: $composing, onSend: { Task { await send() } })
                    .onChange(of: composing) { _, text in
                        typingTask?.cancel()
                        typingTask = Task {
                            try? await Task.sleep(nanoseconds: 400_000_000) // 400 ms
                            await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: !text.isEmpty)
                        }
                    }
            }

            if showNewMsgPill, newIncomingCount > 0 {
                Button {
                    withAnimation {
                        scrollToBottom()
                        showNewMsgPill = false
                        newIncomingCount = 0
                        cancelHidePillTimer()
                    }
                } label: {
                    Label("\(newIncomingCount) nuevo\(newIncomingCount == 1 ? "" : "s")",
                          systemImage: "arrow.down.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 2, y: 1)
                }
                .padding(.bottom, 56)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                ChatTopBar(user: other, isTyping: isTypingOther) { showProfile = true }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 6) }
        .task { await initialLoadAndSubscribe() }
        .onDisappear {
            Task {
                typingTask?.cancel()
                cancelHidePillTimer()
                pollingTask?.cancel()
                pollingTask = nil
                await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: false)
                await DMMessagingService.shared.unsubscribe(conversationID: conversationID)
            }
        }
        .navigationDestination(isPresented: $showProfile) {
            if let other {
                UserProfileView(username: other.username)
            } else {
                Text("Perfil no disponible").foregroundStyle(.secondary)
            }
        }
        .hideTabBarScope() // ⬅️ oculta la barra mientras esta vista exista
    }

    // MARK: - Carga inicial + Realtime
    private func initialLoadAndSubscribe() async {
        await MainActor.run {
            loading = true
            errorText = nil
        }

        do {
            let me = try await DMMessagingService.shared.currentUserID()

            let members = try await DMMessagingService.shared.fetchMembers(conversationID: conversationID)
            let otherID = members.first(where: { $0.autor_id != me })?.autor_id
            let myRead = members.first(where: { $0.autor_id == me })?.last_read_at
            let otherRead = members.first(where: { $0.autor_id == otherID })?.last_read_at
            let typing = (members.first(where: { $0.autor_id == otherID })?.is_typing) ?? false

            await MainActor.run {
                applyMembersSnapshot(me: me, other: otherID, myRead: myRead, otherRead: otherRead, typing: typing)
            }

            let fresh = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, pageSize: 50)
            await MainActor.run {
                upsert(fresh)
                lastKnownLastID = fresh.last?.id
            }

            await MainActor.run {
                if let cut = myLastReadAt {
                    firstUnreadAnchor = messages.first(where: { $0.created_at > cut })?.id
                } else {
                    firstUnreadAnchor = messages.last?.id
                }
            }

            await DMMessagingService.shared.markRead(conversationID: conversationID)

            _ = await DMMessagingService.shared.subscribe(
                conversationID: conversationID,
                handlers: .init(
                    onInserted: { msg in
                        Task { @MainActor in appendIfNew(msg) }
                    },
                    onUpdated: { msg in
                        Task { @MainActor in upsert([msg]) }
                    },
                    onDeletedGlobal: { msgID in
                        Task { @MainActor in messages.removeAll { $0.id == msgID } }
                    },
                    onTypingChanged: { uid, typing in
                        Task { @MainActor in
                            if uid == otherID { isTypingOther = typing }
                        }
                    },
                    onMembersUpdated: { mems in
                        Task { @MainActor in
                            myLastReadAt    = mems.first(where: { $0.autor_id == me })?.last_read_at
                            otherLastReadAt = mems.first(where: { $0.autor_id == otherID })?.last_read_at
                        }
                    }
                )
            )

        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }

        await MainActor.run { loading = false }

        // Fallback polling
        pollingTask?.cancel()
        pollingTask = Task.detached {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            while !Task.isCancelled {
                await fetchNewerSinceLast()
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            }
        }
    }

    private func loadMore() async {
        if isLoadingMore { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        guard let oldest = await MainActor.run(body: { messages.first?.created_at }) else { return }
        do {
            let more = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, before: oldest, pageSize: 50)
            await MainActor.run { upsert(more) }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func fetchNewerSinceLast() async {
        guard let last = await MainActor.run(body: { messages.last?.created_at }) else { return }
        do {
            let newer = try await DMMessagingService.shared.fetchMessages(
                conversationID: conversationID,
                after: last,
                pageSize: 50
            )
            if !newer.isEmpty {
                await MainActor.run { upsert(newer) }
            }
        } catch { /* opcional log */ }
    }

    // MARK: - Acciones
    private func send() async {
        let text = composing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let myID = await MainActor.run(body: { self.myID }) else { return }

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

        await MainActor.run {
            appendIfNew(local)
            composing = ""
        }

        var lastError: Error?
        for attempt in 0...3 {
            do {
                let confirmed = try await DMMessagingService.shared.sendMessage(conversationID: conversationID, text: text, clientTag: tag)
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.client_tag == tag }) {
                        var msg = confirmed; msg._delivery = .sent
                        messages[idx] = msg
                    } else {
                        var msg = confirmed; msg._delivery = .sent
                        appendIfNew(msg)
                    }
                }
                await DMMessagingService.shared.setTyping(conversationID: conversationID, typing: false)
                await DMMessagingService.shared.markRead(conversationID: conversationID)
                return
            } catch {
                lastError = error
                if attempt < 3 { try? await Task.sleep(nanoseconds: UInt64(400_000_000 * (attempt + 1))) }
            }
        }

        await MainActor.run {
            if let idx = messages.firstIndex(where: { $0.client_tag == tag }) {
                messages[idx]._delivery = .failed
            }
            composing = text
            errorText = lastError?.localizedDescription
        }
    }

    private func edit(_ msg: DMMessage, newText: String) async {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let updated = try await DMMessagingService.shared.editMessage(messageID: msg.id, newText: trimmed)
            await MainActor.run { upsert([updated]) }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func deleteForAll(_ msg: DMMessage) async {
        do {
            _ = try await DMMessagingService.shared.deleteMessageForAll(messageID: msg.id)
            await MainActor.run { messages.removeAll { $0.id == msg.id } }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }

    private func deleteForMe(_ msg: DMMessage) async {
        await DMMessagingService.shared.hideMessageForMe(conversationID: conversationID, messageID: msg.id)
        await MainActor.run { messages.removeAll { $0.id == msg.id } }
    }

    // MARK: - Helpers
    private func seenByOther(_ msg: DMMessage) -> Bool {
        guard msg.autor_id == myID, let otherRead = otherLastReadAt else { return false }
        return otherRead >= msg.created_at
    }

    private func scrollToBottom() {
        // El onChange de `messages` baja cuando detecta que estamos al fondo.
    }

    private func startHidePillTimer() {
        hidePillTask?.cancel()
        hidePillTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !isAtBottom { withAnimation { showNewMsgPill = false } }
        }
    }

    private func cancelHidePillTimer() {
        hidePillTask?.cancel()
        hidePillTask = nil
    }

    @MainActor
    private func upsert(_ newMessages: [DMMessage]) {
        var byId = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        for m in newMessages { byId[m.id] = m }
        messages = byId.values
            .filter { $0.deleted_for_all_at == nil }
            .sorted { $0.created_at < $1.created_at }
    }

    @MainActor
    private func appendIfNew(_ m: DMMessage) {
        guard !messages.contains(where: { $0.id == m.id }) else { return }
        messages.append(m)
        messages.sort { $0.created_at < $1.created_at }
    }

    @MainActor
    private func applyMembersSnapshot(me: UUID, other: UUID?, myRead: Date?, otherRead: Date?, typing: Bool) {
        self.myID = me
        self.otherID = other
        self.myLastReadAt = myRead
        self.otherLastReadAt = otherRead
        self.isTypingOther = typing
    }
}
