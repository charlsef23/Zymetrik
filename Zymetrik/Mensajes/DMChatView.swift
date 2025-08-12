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
            // Lista de mensajes (ascendente)
            ScrollViewReader { proxy in
                List {
                    if hasMore {
                        HStack {
                            Spacer()
                            ProgressView().onAppear { Task { await loadMore() } }
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                    
                    ForEach(messages, id: \.id) { msg in
                        MessageRow(message: msg)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .onChange(of: messages) { _, _ in
                    // Auto-scroll al final al recibir nuevos
                    if let last = messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
            
            // Composer
            HStack(spacing: 8) {
                TextField("Mensaje…", text: $composing, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .disabled(composing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(other?.username ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .center) {
            if loading { ProgressView() }
        }
        .task { await initialLoad() }
        .onDisappear { Task { await DMMessagingService.shared.unsubscribe(conversationID: conversationID) } }
    }
    
    // MARK: - Helpers de mensajes (evita duplicados)
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
    
    // MARK: - Load inicial
    private func initialLoad() async {
        loading = true; errorText = nil
        do {
            let fresh = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, pageSize: 30)
            upsert(fresh)
            oldestLoadedAt = messages.first?.created_at
            hasMore = (fresh.count == 30)
            try await DMMessagingService.shared.subscribeToConversation(conversationID: conversationID) { newMsg in
                DispatchQueue.main.async {
                    self.appendIfNew(newMsg)
                }
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
            print("Load more error:", error)
        }
    }
    
    private func send() async {
        let text = composing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        composing = ""
        do {
            try await DMMessagingService.shared.sendMessage(conversationID: conversationID, text: text)
            let latest = try await DMMessagingService.shared.fetchMessages(conversationID: conversationID, pageSize: 1)
            if let last = latest.last { appendIfNew(last) }
        } catch {
            composing = text
        }
    }
}

private struct MessageRow: View {
    let message: DMMessage
    @State private var myID: UUID?
    
    var body: some View {
        HStack {
            if isMine {
                Spacer(minLength: 50)
                Text(message.content)
                    .padding(10)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text(message.content)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Spacer(minLength: 50)
            }
        }
        .padding(.vertical, 2)
        .task {
            if myID == nil {
                myID = try? await DMMessagingService.shared.currentUserID()
            }
        }
    }
    
    private var isMine: Bool {
        guard let myID else { return false }
        return message.autor_id == myID
    }
}
