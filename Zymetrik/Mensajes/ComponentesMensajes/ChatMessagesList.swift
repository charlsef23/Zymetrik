import SwiftUI
import Foundation

struct ChatMessagesList: View {
    let mensajes: [ChatMessage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mensajes) { mensaje in
                        HStack {
                            if mensaje.isCurrentUser { Spacer() }

                            VStack(alignment: mensaje.isCurrentUser ? .trailing : .leading) {
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
                .padding(.top, 12)
            }
            .onChange(of: mensajes) { _, nuevos in
                if let ultimo = nuevos.last {
                    withAnimation {
                        proxy.scrollTo(ultimo.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}
