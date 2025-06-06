import SwiftUI

struct MensajesView: View {
    // Lista de chats simulados
    let chats = [
        (usuario: "Carlos", foto: "foto_perfil"),
        (usuario: "gymbro", foto: "persona1"),
        (usuario: "carla_fit", foto: "persona2"),
        (usuario: "lu_entrena", foto: "persona3")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(chats, id: \.usuario) { chat in
                    NavigationLink(destination: ChatView(usuario: chat.usuario, foto: chat.foto)) {
                        HStack(spacing: 12) {
                            Image(chat.foto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.usuario)
                                    .font(.headline)
                                Text("Último mensaje aquí...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("09:12")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Mensajes")
        }
    }
}
