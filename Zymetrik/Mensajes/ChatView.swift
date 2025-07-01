import SwiftUI

struct ChatView: View {
    let chatID: UUID
    let receptorUsername: String
    let avatarURL: String?

    @State private var mensajes: [ChatMessage] = []
    @State private var nuevoMensaje = ""
    @FocusState private var campoEnfocado: Bool

    var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView(receptorUsername: receptorUsername, avatarURL: avatarURL)

            Divider()

            ChatMessagesList(mensajes: mensajes)
            
            ChatInputField(
                mensaje: $nuevoMensaje,
                campoEnfocado: _campoEnfocado,
                onSend: enviarMensaje
            )
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            cargarMensajes()
        }
        .onTapGesture {
            campoEnfocado = false
        }
    }

    func cargarMensajes() {
        Task {
            do {
                let resultado = try await SupabaseService.shared.fetchMensajes(chatID: chatID)
                mensajes = resultado
            } catch {
                print("❌ Error al cargar mensajes:", error)
            }
        }
    }

    func enviarMensaje() {
        guard !nuevoMensaje.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        Task {
            do {
                let enviado = try await SupabaseService.shared.enviarMensaje(chatID: chatID, contenido: nuevoMensaje)
                mensajes.append(enviado)
                nuevoMensaje = ""
            } catch {
                print("❌ Error al enviar mensaje:", error)
            }
        }
    }
}
