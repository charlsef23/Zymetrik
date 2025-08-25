import SwiftUI

struct DMChatView: View {
    let conversationID: UUID
    let other: PerfilLite?

    @State private var messages: [DMMessage] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var composing: String = ""

    @State private var oldestLoadedAt: Date?
    @State private var hasMore = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                RefreshableScrollView(topRefresh: {
                    await loadMore()
                }) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if loading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        } else if let errorText {
                            Text(errorText).foregroundColor(.secondary).padding(.vertical, 8)
                        }

                        ForEach(groupedByDay(), id: \.date) { section in
                            Section {
                                ForEach(section.items, id: \.id) { msg in
                                    MessageBubble(message: msg)
                                        .id(msg.id)
                                        .padding(.horizontal, 12)
                                }
                            } header: {
                                Text(section.title)
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                        }

                        Color.clear.frame(height: 8).id("BOTTOM_ANCHOR")
                    }
                    .padding(.top, 6)
                    .onChange(of: messages) { _, _ in
                        withAnimation { proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom) }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                    }
                }
            }

            ComposerBar(text: $composing, onSend: { Task { await send() } })
        }
        .navigationTitle(other?.username ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 6) }
        .task { await initialLoad() }
        .onDisappear { DMMessagingService.shared.stopPolling(conversationID: conversationID) }
    }

    // MARK: - Carga
    private func initialLoad() async {
        loading = true; errorText = nil
        do {
            let fresh = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, pageSize: 30)
            messages = fresh
            oldestLoadedAt = messages.first?.created_at
            hasMore = (fresh.count == 30)

            let lastDate = messages.last?.created_at
            DMMessagingService.shared.startPolling(conversationID: conversationID, since: lastDate) { newMsg in
                DispatchQueue.main.async { appendIfNew(newMsg) }
            }
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func loadMore() async {
        guard hasMore else { return }
        do {
            let more = try await DMMessagingService.shared.fetchMessages(
                conversationID: conversationID,
                before: oldestLoadedAt,
                pageSize: 30
            )
            if more.isEmpty {
                hasMore = false
            } else {
                upsert(more)
                oldestLoadedAt = messages.first?.created_at
                hasMore = (more.count == 30)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func send() async {
        let text = composing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Mensaje optimista con client_tag
        let tag = UUID().uuidString
        let myID = (try? await DMMessagingService.shared.currentUserID()) ?? UUID()

        var local = DMMessage(
            id: UUID(), conversation_id: conversationID, autor_id: myID,
            content: text, created_at: Date(), client_tag: tag, _delivery: .pending
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
        } catch {
            if let idx = messages.firstIndex(where: { $0.client_tag == tag }) {
                messages[idx]._delivery = .failed
            }
            composing = text // dejar para reintento manual
        }
    }

    // MARK: - Helpers
    private func upsert(_ newMessages: [DMMessage]) {
        var byId = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        for m in newMessages { byId[m.id] = m }
        messages = byId.values.sorted { $0.created_at < $1.created_at }
    }

    private func appendIfNew(_ m: DMMessage) {
        guard !messages.contains(where: { $0.id == m.id }) else { return }
        messages.append(m)
        messages.sort { $0.created_at < $1.created_at }
    }

    private func groupedByDay() -> [(date: Date, title: String, items: [DMMessage])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: messages) { cal.startOfDay(for: $0.created_at) }
        let sortedKeys = groups.keys.sorted()
        let df = DateFormatter()
        df.locale = .current
        df.dateStyle = .medium
        df.doesRelativeDateFormatting = true

        return sortedKeys.map { day in
            let title = df.string(from: day)
            let items = (groups[day] ?? []).sorted { $0.created_at < $1.created_at }
            return (day, title, items)
        }
    }
}

// MARK: - Subvistas

private struct MessageBubble: View {
    let message: DMMessage
    @State private var myID: UUID?

    private var isMine: Bool {
        guard let myID else { return false }
        return message.autor_id == myID
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(10)
                    .background(isMine ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 6) {
                    Text(timeString(message.created_at))
                        .font(.caption2).foregroundStyle(.secondary)
                    if isMine, let state = message._delivery {
                        Image(systemName: state == .sent ? "checkmark.circle.fill" :
                                            state == .pending ? "clock.badge" : "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundStyle(state == .failed ? .red : .secondary)
                    }
                }
                .padding(.leading, 6)
            }

            if !isMine { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
        .task {
            if myID == nil {
                myID = try? await DMMessagingService.shared.currentUserID()
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}

private struct ComposerBar: View {
    @Binding var text: String
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Mensaje…", text: $text, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .lineLimit(1...5)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            Button(action: onSend) {
                Image(systemName: "paperplane.fill").font(.system(size: 18, weight: .semibold))
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// ScrollView con refresh superior
struct RefreshableScrollView<Content: View>: View {
    var topRefresh: (() async -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            if let topRefresh {
                VStack { Color.clear.frame(height: 1) }
                    .refreshable { await topRefresh() }
            }
            content()
        }
    }
}
