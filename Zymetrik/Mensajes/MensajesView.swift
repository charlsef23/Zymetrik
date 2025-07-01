import SwiftUI
import Supabase

struct MensajesView: View {
    @State private var chats: [ChatPreview] = []
    @State private var cargando = true

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if cargando {
                        ProgressView()
                    } else {
                        ForEach(chats) { chat in
                            NavigationLink(destination: ChatView(chatID: chat.id, receptorUsername: chat.receptorUsername, avatarURL: chat.avatarURL)) {
                                HStack(spacing: 12) {
                                    AvatarAsyncImage(
                                        url: URL(string: chat.avatarURL ?? ""),
                                        size: 50
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chat.nombre)
                                            .font(.headline)
                                        Text(chat.ultimoMensaje)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(chat.horaUltimoMensaje)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                            }
                            .id(chat.id)
                        }
                        .onDelete(perform: borrarChat)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Mensajes")
                .refreshable {
                    await recargarChats()
                }
                .onAppear {
                    cargarChats {
                        if let ultimo = chats.last {
                            withAnimation {
                                proxy.scrollTo(ultimo.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    // 🚀 Cargar chats con callback opcional
    func cargarChats(completion: (() -> Void)? = nil) {
        Task {
            do {
                cargando = true
                chats = try await SupabaseService.shared.fetchChatPreviews()
                cargando = false
                completion?()
            } catch {
                print("❌ Error al cargar chats:", error)
                cargando = false
            }
        }
    }

    // 🔁 Pull to refresh
    func recargarChats() async {
        do {
            chats = try await SupabaseService.shared.fetchChatPreviews()
        } catch {
            print("❌ Error al refrescar chats:", error)
        }
    }

    // 🗑️ Borrar con swipe (opcional: eliminar también en Supabase)
    func borrarChat(at offsets: IndexSet) {
        withAnimation {
            chats.remove(atOffsets: offsets)
        }
        // Aquí podrías llamar a Supabase para borrar el chat real si quieres
    }
}
