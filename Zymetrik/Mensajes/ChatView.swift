import SwiftUI

struct ChatView: View {
    let usuario: String
    @State private var nuevoMensaje = ""
    @State private var mensajes: [Mensaje] = [
        Mensaje(texto: "¡Hola!", esUsuarioActual: false),
        Mensaje(texto: "¿Entrenamos hoy?", esUsuarioActual: true)
    ]

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(mensajes) { mensaje in
                        HStack {
                            if mensaje.esUsuarioActual {
                                Spacer()
                                Text(mensaje.texto)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .frame(maxWidth: 240, alignment: .trailing)
                            } else {
                                Text(mensaje.texto)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.black)
                                    .cornerRadius(16)
                                    .frame(maxWidth: 240, alignment: .leading)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }

            HStack {
                TextField("Escribe un mensaje", text: $nuevoMensaje)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button(action: {
                    let mensaje = Mensaje(texto: nuevoMensaje, esUsuarioActual: true)
                    mensajes.append(mensaje)
                    nuevoMensaje = ""
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
        }
        .navigationTitle(usuario)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Mensaje: Identifiable {
    let id = UUID()
    let texto: String
    let esUsuarioActual: Bool
}
