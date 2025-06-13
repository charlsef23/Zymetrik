import SwiftUI

class GuardadosManager: ObservableObject {
    static let shared = GuardadosManager()

    @Published var postsGuardados: [EntrenamientoPost] = []
    @Published var carpetas: [CarpetaGuardado] = []

    private init() {}

    // Añadir o quitar un post de la lista general
    func toggle(post: EntrenamientoPost) {
        if contiene(post) {
            postsGuardados.removeAll { $0.id == post.id }
            eliminarDeTodasLasCarpetas(post)
        } else {
            postsGuardados.append(post)
        }
    }

    // Verificar si un post está guardado en general
    func contiene(_ post: EntrenamientoPost) -> Bool {
        postsGuardados.contains { $0.id == post.id }
    }

    // Crear carpeta y devolverla
    @MainActor
    func crearCarpeta(nombre: String) -> CarpetaGuardado {
        let nueva = CarpetaGuardado(nombre: nombre, posts: [])
        carpetas.append(nueva)
        return nueva
    }

    // Añadir post a una carpeta específica
    func añadir(post: EntrenamientoPost, a carpeta: CarpetaGuardado) {
        if let index = carpetas.firstIndex(where: { $0.id == carpeta.id }) {
            if !carpetas[index].posts.contains(where: { $0.id == post.id }) {
                carpetas[index].posts.append(post)

                // También se añade al general si no estaba
                if !postsGuardados.contains(where: { $0.id == post.id }) {
                    postsGuardados.append(post)
                }
            }
        }
    }

    // Eliminar un post de todas las carpetas
    func eliminarDeTodasLasCarpetas(_ post: EntrenamientoPost) {
        for i in carpetas.indices {
            carpetas[i].posts.removeAll { $0.id == post.id }
        }
    }

    // Eliminar carpeta
    func eliminarCarpeta(_ carpeta: CarpetaGuardado) {
        carpetas.removeAll { $0.id == carpeta.id }
    }

    // Renombrar carpeta
    func renombrarCarpeta(_ carpeta: CarpetaGuardado, nuevoNombre: String) {
        if let index = carpetas.firstIndex(where: { $0.id == carpeta.id }) {
            carpetas[index].nombre = nuevoNombre
        }
    }
}
