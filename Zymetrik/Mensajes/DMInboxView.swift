import SwiftUI

struct DMInboxItem: Identifiable, Hashable {
    let id: UUID
    let conversation: DMConversation
    let otherPerfil: PerfilLite?
    let lastMessagePreview: String?
    let lastAt: Date?
}

struct DMInboxView: View {
    @State private var items: [DMInboxItem] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var pushChat: DMInboxItem?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Cargando conversaciones…")
                } else if let errorText {
                    VStack(spacing: 12) {
                        Text("Error").font(.headline)
                        Text(errorText).foregroundColor(.secondary)
                        Button("Reintentar") { Task { await load() } }
                    }
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "Sin mensajes",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Empieza una conversación desde un perfil.")
                    )
                } else {
                    List(items) { it in
                        Button { pushChat = it } label: {
                            HStack(spacing: 12) {
                                AvatarAsyncImage(url: URL(string: it.otherPerfil?.avatar_url ?? ""), size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(it.otherPerfil?.username ?? "Conversación")
                                        .font(.headline)
                                    Text(it.lastMessagePreview ?? "—")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let date = it.lastAt {
                                    Text(shortDate(date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Mensajes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(
                        destination: DMNewChatView(onCreated: { convID, user in
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
                    ) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task { await load() }
            .navigationDestination(item: $pushChat) { it in
                DMChatView(conversationID: it.id, other: it.otherPerfil)
            }
        }
    }

    // MARK: - Data
    private func load() async {
        loading = true; errorText = nil
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

                            // 🔹 Intenta obtener el ÚLTIMO mensaje real (DESC LIMIT 1)
                            let last: DMMessage?
                            do {
                                last = try await svc.fetchLastMessage(conversationID: conv.id)
                            } catch {
                                // Fallback si la RPC no existe: usa la antigua (ASC) y coge el .last
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
                            return nil // omitimos convs con fallo puntual
                        }
                    }
                }
                for try await item in group {
                    if let item { temp.append(item) }
                }
            }

            self.items = temp.sorted { (a, b) in
                (a.lastAt ?? .distantPast) > (b.lastAt ?? .distantPast)
            }
        } catch {
            self.errorText = error.localizedDescription
        }
        loading = false
    }

    private func shortDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.doesRelativeDateFormatting = true
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
