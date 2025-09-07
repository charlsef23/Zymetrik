import SwiftUI

struct PostView: View {
    let post: Post
    var onPostEliminado: (() -> Void)?
    var onGuardadoCambio: ((Bool) -> Void)? = nil

    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false
    @State private var mostrarConfirmacionEliminar = false

    // Evita re-disparos en reappear (scroll)
    @State private var didPrime = false
    @State private var primeTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PostHeader(post: post) { mostrarConfirmacionEliminar = true }

            if let ejercicio = ejercicioSeleccionado {
                EjercicioEstadisticasView(ejercicio: ejercicio)
            }

            CarruselEjerciciosView(
                ejercicios: post.contenido,
                ejercicioSeleccionado: $ejercicioSeleccionado
            )

            PostActionsView(
                leDioLike: $leDioLike,
                numLikes: $numLikes,
                guardado: $guardado,
                mostrarComentarios: $mostrarComentarios,
                toggleLike: toggleLike,
                toggleSave: toggleSave
            )
        }
        .padding()
        .onAppear {
            if !didPrime {
                didPrime = true
                ejercicioSeleccionado = post.contenido.first

                // Paraleliza 3 llamadas; menos latencia percibida
                primeTask?.cancel()
                primeTask = Task {
                    await primePostMeta()
                }
            }
        }
        .onDisappear { primeTask?.cancel() }
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) { eliminarPost() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Prime de meta (paralelo)
    private func primePostMeta() async {
        async let liked: Bool = (try? await SupabaseService.shared.didLike(postID: post.id)) ?? false
        async let count: Int  = (try? await SupabaseService.shared.countLikes(postID: post.id)) ?? 0
        async let saved: Bool = (try? await SupabaseService.shared.didSave(postID: post.id)) ?? false

        let (l, c, s) = await (liked, count, saved)

        await MainActor.run {
            leDioLike = l
            numLikes = c
            guardado = s
        }
    }

    // MARK: - Eliminar
    private func eliminarPost() {
        Task {
            do {
                try await SupabaseService.shared.eliminarPost(postID: post.id)
                onPostEliminado?()
            } catch {
                print("❌ Error al eliminar el post: \(error)")
            }
        }
    }

    // MARK: - Likes
    private func toggleLike() async {
        await MainActor.run {
            leDioLike.toggle()
            numLikes += leDioLike ? 1 : -1
        }
        do {
            try await SupabaseService.shared.setLike(postID: post.id, like: leDioLike)
        } catch {
            print("❌ Error al cambiar like: \(error)")
            await MainActor.run {
                leDioLike.toggle()
                numLikes += leDioLike ? 1 : -1
            }
        }
    }

    // MARK: - Guardados
    private func toggleSave() async {
        await MainActor.run { guardado.toggle() }
        do {
            try await SupabaseService.shared.setSaved(postID: post.id, saved: guardado)
            await MainActor.run { onGuardadoCambio?(guardado) }
        } catch {
            print("❌ Error al cambiar guardado: \(error)")
            await MainActor.run {
                guardado.toggle()
                onGuardadoCambio?(guardado)
            }
        }
    }
}
