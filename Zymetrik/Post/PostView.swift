import SwiftUI

struct PostView: View {
    let post: Post
    var onPostEliminado: (() -> Void)?
    @State private var ejercicioSeleccionado: EjercicioPostContenido?
    @State private var leDioLike = false
    @State private var numLikes = 0
    @State private var guardado = false
    @State private var mostrarComentarios = false
    @State private var mostrarConfirmacionEliminar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PostHeader(post: post, onEliminar: {
                mostrarConfirmacionEliminar = true
            })

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
                toggleLike: toggleLike
            )
        }
        .padding()
        .onAppear {
            ejercicioSeleccionado = post.contenido.first
            Task {
                await comprobarSiLeDioLike()
                await cargarNumeroDeLikes()
            }
        }
        .sheet(isPresented: $mostrarComentarios) {
            ComentariosView(postID: post.id)
        }
        .alert("¿Eliminar este post?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) {
                eliminarPost()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func eliminarPost() {
        Task {
            do {
                try await SupabaseService.shared.eliminarPost(postID: post.id)
                print("✅ Post eliminado con éxito")
                onPostEliminado?()  // Notificar al padre
            } catch {
                print("❌ Error al eliminar el post: \(error)")
            }
        }
    }
    private func comprobarSiLeDioLike() async {
        // Implementación
    }

    private func toggleLike() async {
        // Implementación
    }

    private func cargarNumeroDeLikes() async {
        // Implementación
    }
}

