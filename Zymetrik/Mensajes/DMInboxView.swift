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
                    ContentUnavailableView("Sin mensajes",
                                           systemImage: "bubble.left.and.bubble.right",
                                           description: Text("Empieza una conversación desde un perfil."))
                } else {
                    List(items) { it in
                        Button {
                            pushChat = it
                        } label: {
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
                }
            }
            .navigationTitle("Mensajes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: DMNewChatView(onCreated: { convID in
                        Task { await load() }
                    })) {
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
    
    private func load() async {
        loading = true; errorText = nil
        do {
            let svc = DMMessagingService.shared
            let myID = try await svc.currentUserID()
            let convs = try await svc.fetchConversations()
            
            // Para cada conversación, obtenemos miembros y perfil del otro usuario
            var temp: [DMInboxItem] = []
            for conv in convs {
                let members = try await svc.fetchMembers(conversationID: conv.id)
                let otherID = members.map(\.autor_id).first { $0 != myID }
                var other: PerfilLite? = nil
                if let oid = otherID { other = try? await svc.fetchPerfil(id: oid) }
                
                // Cargar último mensaje (rápido: pageSize 1)
                let last = try await svc.fetchMessages(conversationID: conv.id, pageSize: 1).last
                temp.append(.init(
                    id: conv.id,
                    conversation: conv,
                    otherPerfil: other,
                    lastMessagePreview: last?.content,
                    lastAt: conv.last_message_at ?? last?.created_at
                ))
            }
            self.items = temp
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
