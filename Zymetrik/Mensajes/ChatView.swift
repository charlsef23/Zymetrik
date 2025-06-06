import SwiftUI

// Modelo de mensaje
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isCurrentUser: Bool
    let time: String
}

struct ChatView: View {
    let usuario: String
    let foto: String

    @State private var mensajes: [ChatMessage] = [
        ChatMessage(text: "Hola! ¿Listo para entrenar?", isCurrentUser: false, time: "09:03"),
        ChatMessage(text: "¡Claro! Nos vemos en 10 minutos", isCurrentUser: true, time: "09:05"),
        ChatMessage(text: "Perfecto 🔥", isCurrentUser: false, time: "09:06")
    ]

    @State private var nuevoMensaje = ""
    @State private var irAlPerfil = false
    @FocusState private var campoEnfocado: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Encabezado con foto y nombre
            Button {
                irAlPerfil = true
            } label: {
                HStack(spacing: 12) {
                    Image(foto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(usuario)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("En línea")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
            }

            Divider()

            // Lista de mensajes
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mensajes) { mensaje in
                            HStack {
                                if mensaje.isCurrentUser { Spacer() }

                                VStack(alignment: mensaje.isCurrentUser ? .trailing : .leading, spacing: 4) {
                                    Text(mensaje.text)
                                        .padding()
                                        .background(mensaje.isCurrentUser ? Color.black : Color(.systemGray5))
                                        .foregroundColor(mensaje.isCurrentUser ? .white : .black)
                                        .cornerRadius(16)

                                    Text(mensaje.time)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }

                                if !mensaje.isCurrentUser { Spacer() }
                            }
                            .padding(.horizontal)
                            .id(mensaje.id)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: mensajes) { _, nuevosMensajes in
                    if let ultimo = nuevosMensajes.last {
                        withAnimation {
                            proxy.scrollTo(ultimo.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Campo para escribir mensaje
            HStack {
                TextField("Mensaje...", text: $nuevoMensaje)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($campoEnfocado)

                Button {
                    if !nuevoMensaje.isEmpty {
                        let hora = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
                        withAnimation {
                            mensajes.append(ChatMessage(text: nuevoMensaje, isCurrentUser: true, time: hora))
                        }
                        nuevoMensaje = ""
                        campoEnfocado = false
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                        .font(.title3)
                        .padding(10)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .navigationDestination(isPresented: $irAlPerfil) {
            UserProfileView(username: usuario)
        }
        .onTapGesture {
            campoEnfocado = false
        }
    }
}

#Preview {
    ChatView(usuario: "Carlos", foto: "foto_perfil")
}
