import SwiftUI

struct ComentariosView: View {
    let postID: UUID
    @State private var comentarios: [Comentario] = []
    @State private var nuevoComentario: String = ""
    @State private var respondiendoA: Comentario? = nil

    // Paginación
    @State private var loading = false
    @State private var reachedEnd = false
    @State private var beforeCursor: Date? = nil // carga hacia atrás (más antiguos)

    var comentariosRaiz: [Comentario] {
        comentarios.filter { $0.comentario_padre_id == nil }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Comentarios")
                    .font(.headline)

                ForEach(comentariosRaiz) { comentario in
                    comentarioView(comentario, nivel: 0)
                        .onAppear { // infinite scroll
                            if comentario.id == comentariosRaiz.last?.id {
                                Task { await loadMore() }
                            }
                        }
                }

                if loading { HStack { Spacer(); ProgressView(); Spacer() } }

                Divider().padding(.vertical, 4)

                if let respondiendoA = respondiendoA {
                    HStack {
                        Text("Respondiendo a @\(respondiendoA.username)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("Cancelar") { self.respondiendoA = nil }
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }

                HStack {
                    TextField("Añade un comentario...", text: $nuevoComentario)
                        .textFieldStyle(.roundedBorder)
                    Button("Enviar") { Task { await enviarComentario() } }
                }
            }
            .padding()
        }
        .refreshable { await refresh() }
        .task { await initialLoad() }
    }

    // MARK: - Estructura recursiva
    func comentarioView(_ comentario: Comentario, nivel: Int = 0) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comentario.username)")
                        .font(.caption.bold())
                    Spacer()
                    Button("Responder") { respondiendoA = comentario }
                        .font(.caption2)
                }
                Text(comentario.contenido)
                    .font(.subheadline)

                // Hijos
                let respuestas = comentarios.filter { $0.comentario_padre_id == comentario.id }
                if !respuestas.isEmpty {
                    Divider().opacity(0.3)
                    ForEach(respuestas) { respuesta in
                        comentarioView(respuesta, nivel: nivel + 1)
                            .padding(.leading, CGFloat((nivel + 1) * 20))
                    }
                }
            }
        )
    }

    // MARK: - Carga
    private func initialLoad() async {
        if comentarios.isEmpty { await refresh() }
    }

    private func refresh() async {
        reachedEnd = false
        beforeCursor = nil
        await loadMore(reset: true)
    }

    private func loadMore(reset: Bool = false) async {
        guard !loading, !reachedEnd else { return }
        loading = true
        defer { loading = false }

        do {
            struct P: Encodable {
                let p_post: UUID
                let p_before: String?
                let p_limit: Int
            }
            let iso = ISO8601DateFormatter()
            let p = P(
                p_post: postID,
                p_before: beforeCursor.map { iso.string(from: $0) },
                p_limit: 50
            )
            let res = try await SupabaseManager.shared.client
                .rpc("get_post_comments", params: p)
                .execute()
            let page = try res.decodedList(to: Comentario.self)

            if reset {
                comentarios = page
            } else {
                // Append por ID, evita duplicados si refresca
                var dict = Dictionary(uniqueKeysWithValues: comentarios.map { ($0.id, $0) })
                for c in page { dict[c.id] = c }
                comentarios = dict.values.sorted { $0.creado_en < $1.creado_en }
            }

            if page.isEmpty {
                reachedEnd = true
            } else {
                beforeCursor = page.first?.creado_en // vienen desc por fecha en la RPC; si los ordenas asc, usa .last
            }
        } catch {
            print("❌ Error al cargar comentarios: \(error)")
        }
    }

    // MARK: - Enviar (append local y no recargar todo)
    private func enviarComentario() async {
        let trimmed = nuevoComentario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let nuevo = NuevoComentario(
                post_id: postID,
                autor_id: session.user.id,
                contenido: trimmed,
                comentario_padre_id: respondiendoA?.id
            )

            // Insert y devuelve el comentario con perfil.username
            let res = try await SupabaseManager.shared.client
                .from("comentarios")
                .insert(nuevo)
                .select("*, perfil:autor_id(username)") // trae username junto al comentario
                .single()
                .execute()

            let creado = try res.decoded(to: Comentario.self)

            // Añade sin mutar propiedades
            comentarios.append(creado)
            comentarios.sort { $0.creado_en < $1.creado_en }

            await MainActor.run {
                nuevoComentario = ""
                respondiendoA = nil
            }
        } catch {
            print("❌ Error al enviar comentario: \(error)")
        }
    }

    private func usernameActual() async throws -> String {
        let s = try await SupabaseManager.shared.client.auth.session
        let r = try await SupabaseManager.shared.client
            .from("perfil")
            .select("username")
            .eq("id", value: s.user.id.uuidString)
            .single()
            .execute()
        struct U: Decodable { let username: String }
        return try r.decoded(to: U.self).username
    }
}
