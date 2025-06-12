import SwiftUI

struct ComentariosView: View {
    let post: EntrenamientoPost
    @State private var comentarios: [String] = [
        "¡Muy buen entrenamiento!",
        "¿Cuántas repes hiciste?",
        "Inspirador 💪"
    ]
    @State private var nuevoComentario = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(comentarios, id: \.self) { comentario in
                        HStack(alignment: .top) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(Text("👤"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("usuario")
                                    .fontWeight(.semibold)
                                    .font(.subheadline)

                                Text(comentario)
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)

                Divider()

                HStack {
                    TextField("Añadir un comentario...", text: $nuevoComentario)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Button("Publicar") {
                        if !nuevoComentario.isEmpty {
                            comentarios.append(nuevoComentario)
                            nuevoComentario = ""
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(nuevoComentario.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comentarios")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
