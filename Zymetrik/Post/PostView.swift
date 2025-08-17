import SwiftUI

struct PostView: View {
    let post: Post
    var onPostEliminado: (() -> Void)?
    var onGuardadoCambio: ((Bool) -> Void)? = nil  // 👈 NUEVO

    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false
    @State private var mostrarConfirmacionEliminar = false

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
            ejercicioSeleccionado = post.contenido.first
            Task {
                await comprobarSiLeDioLike()
                await cargarNumeroDeLikes()
                await comprobarSiGuardado()
            }
        }
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) { eliminarPost() }
            Button("Cancelar", role: .cancel) {}
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
    @MainActor
    private func comprobarSiLeDioLike() async {
        do { leDioLike = try await SupabaseService.shared.didLike(postID: post.id) }
        catch { print("❌ Error comprobando like: \(error)") }
    }

    @MainActor
    private func cargarNumeroDeLikes() async {
        do { numLikes = try await SupabaseService.shared.countLikes(postID: post.id) }
        catch { print("❌ Error cargando número de likes: \(error)") }
    }

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
    @MainActor
    private func comprobarSiGuardado() async {
        do { guardado = try await SupabaseService.shared.didSave(postID: post.id) }
        catch { print("❌ Error comprobando guardado: \(error)") }
    }

    private func toggleSave() async {
        // Optimista
        await MainActor.run { guardado.toggle() }

        do {
            try await SupabaseService.shared.setSaved(postID: post.id, saved: guardado)
            // Notifica al padre SOLO si ha ido bien
            await MainActor.run { onGuardadoCambio?(guardado) }
        } catch {
            print("❌ Error al cambiar guardado: \(error)")
            await MainActor.run {
                guardado.toggle() // revertir
                onGuardadoCambio?(guardado) // notifica estado real
            }
        }
    }
}
