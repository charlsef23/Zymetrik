import SwiftUI

struct ComentariosView: View {
    let postID: UUID
    @State private var comentarios: [Comentario] = []
    @State private var nuevoComentario: String = ""
    @State private var respondiendoA: Comentario? = nil

    var comentariosRaiz: [Comentario] {
        comentarios.filter { $0.comentario_padre_id == nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Comentarios")
                    .font(.headline)

                ForEach(comentariosRaiz) { comentario in
                    comentarioView(comentario, nivel: 0)
                }

                Divider().padding(.vertical, 4)

                if let respondiendoA = respondiendoA {
                    HStack {
                        Text("Respondiendo a @\(respondiendoA.username)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("Cancelar") {
                            self.respondiendoA = nil
                        }
                        .font(.footnote)
                        .foregroundColor(.red)
                    }
                }

                HStack {
                    TextField("Añade un comentario...", text: $nuevoComentario)
                        .textFieldStyle(.roundedBorder)
                    Button("Enviar") {
                        Task { await enviarComentario() }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task { await cargarComentarios() }
        }
    }

    func comentarioView(_ comentario: Comentario, nivel: Int = 0) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comentario.username)")
                        .font(.caption.bold())
                    Spacer()
                    Button("Responder") {
                        respondiendoA = comentario
                    }
                    .font(.caption2)
                }

                Text(comentario.contenido)
                    .font(.subheadline)

                Divider()

                let respuestas = comentarios.filter { $0.comentario_padre_id == comentario.id }
                ForEach(respuestas) { respuesta in
                    comentarioView(respuesta, nivel: nivel + 1)
                        .padding(.leading, CGFloat((nivel + 1) * 20))
                }
            }
        )
    }

    func cargarComentarios() async {
        do {
            let response = try await SupabaseManager.shared.client
                .from("comentarios")
                .select("*, profiles(username)")
                .eq("post_id", value: postID)
                .order("creado_en", ascending: true)
                .execute()

            let data = try response.decoded(to: [Comentario].self)
            self.comentarios = data
        } catch {
            print("❌ Error al cargar comentarios: \(error)")
        }
    }

    func enviarComentario() async {
        guard !nuevoComentario.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        do {
            let session = try await SupabaseManager.shared.client.auth.session

            let nuevo = NuevoComentario(
                post_id: postID,
                profile_id: session.user.id,
                contenido: nuevoComentario,
                comentario_padre_id: respondiendoA?.id
            )

            _ = try await SupabaseManager.shared.client
                .from("comentarios")
                .insert(nuevo)
                .execute()

            nuevoComentario = ""
            respondiendoA = nil
            await cargarComentarios()
        } catch {
            print("❌ Error al enviar comentario: \(error)")
        }
    }
}


