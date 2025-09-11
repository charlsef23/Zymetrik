import Foundation
import UIKit // Para UIApplication

// MARK: - PerfilActualizado (para EditarPerfilView)
struct PerfilActualizado: Codable {
    let nombre: String
    let username: String
    let presentacion: String
    let enlaces: String
    let avatar_url: String?
    
    // Inicializador desde tu PerfilViewModel existente
    @MainActor
    init(from viewModel: PerfilViewModel) {
        self.nombre = viewModel.nombre
        self.username = viewModel.username
        self.presentacion = viewModel.presentacion
        self.enlaces = viewModel.enlaces
        self.avatar_url = viewModel.imagenPerfilURL
    }
    
    // Inicializador manual
    init(
        nombre: String,
        username: String,
        presentacion: String,
        enlaces: String,
        avatar_url: String? = nil
    ) {
        self.nombre = nombre
        self.username = username
        self.presentacion = presentacion
        self.enlaces = enlaces
        self.avatar_url = avatar_url
    }
    
    // Validación de datos
    func validar() -> (esValido: Bool, errores: [String]) {
        var errores: [String] = []
        
        if nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errores.append("El nombre es obligatorio")
        }
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errores.append("El nombre de usuario es obligatorio")
        }
        
        if username.count < 3 {
            errores.append("El nombre de usuario debe tener al menos 3 caracteres")
        }
        
        if username.contains(" ") {
            errores.append("El nombre de usuario no puede contener espacios")
        }
        
        if !enlaces.isEmpty && !enlaces.isValidURL {
            errores.append("El enlace no es válido")
        }
        
        if presentacion.count > 150 {
            errores.append("La presentación no puede tener más de 150 caracteres")
        }
        
        return (errores.isEmpty, errores)
    }
}

// MARK: - Extensiones para tus modelos existentes

extension PerfilDTO {
    // Convertir a PerfilActualizado para edición
    func toPerfilActualizado() -> PerfilActualizado {
        return PerfilActualizado(
            nombre: nombre ?? "",
            username: username ?? "",
            presentacion: presentacion ?? "",
            enlaces: enlaces ?? "",
            avatar_url: avatar_url
        )
    }
    
    // Propiedades computadas para valores seguros
    var nombreSeguro: String {
        return nombre ?? ""
    }
    
    var usernameSeguro: String {
        return username ?? ""
    }
    
    var presentacionSegura: String {
        return presentacion ?? ""
    }
    
    var enlacesSeguro: String {
        return enlaces ?? ""
    }
}

extension PerfilResumen {
    // Convertir a formato de avatar URL
    var avatarURL: URL? {
        guard let urlString = avatar_url else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Extensión para PerfilViewModel con funciones de avatar

extension PerfilViewModel {
    // Actualizar avatar específicamente
    @MainActor
    func actualizarAvatar(_ nuevaURL: String) async {
        self.imagenPerfilURL = nuevaURL
        
        // Guardar en base de datos
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let uid = session.user.id.uuidString
            
            try await SupabaseManager.shared.client
                .from("perfil")
                .update(["avatar_url": nuevaURL])
                .eq("id", value: uid)
                .execute()
            
        } catch {
            print("❌ Error al actualizar avatar: \(error)")
            self.errorText = "Error al actualizar avatar"
        }
    }
    
    // Obtener PerfilActualizado del estado actual
    @MainActor
    func getPerfilActualizado() -> PerfilActualizado {
        return PerfilActualizado(from: self)
    }
    
    // Actualizar desde PerfilActualizado
    @MainActor
    func actualizar(desde perfil: PerfilActualizado) {
        self.nombre = perfil.nombre
        self.username = perfil.username
        self.presentacion = perfil.presentacion
        self.enlaces = perfil.enlaces
        self.imagenPerfilURL = perfil.avatar_url
    }
}

// MARK: - Extensión para validar URLs
extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Errores específicos de perfil
enum PerfilError: LocalizedError {
    case datosIncompletos
    case usernameYaExiste
    case errorDeRed
    case errorDeAutorizacion
    case avatarMuyGrande
    case formatoAvatarInvalido
    
    var errorDescription: String? {
        switch self {
        case .datosIncompletos:
            return "Por favor completa todos los campos obligatorios"
        case .usernameYaExiste:
            return "Este nombre de usuario ya está en uso"
        case .errorDeRed:
            return "Error de conexión. Intenta de nuevo"
        case .errorDeAutorizacion:
            return "No tienes permisos para realizar esta acción"
        case .avatarMuyGrande:
            return "La imagen es muy grande. Máximo 5MB"
        case .formatoAvatarInvalido:
            return "Formato de imagen no válido. Usa JPG o PNG"
        }
    }
}

// MARK: - Constantes para tu sistema
struct PerfilConstantes {
    static let maxLongitudNombre = 50
    static let maxLongitudUsername = 30
    static let minLongitudUsername = 3
    static let maxLongitudPresentacion = 150
    static let maxLongitudEnlaces = 200
    static let maxTamañoAvatar = 5 * 1024 * 1024 // 5MB
    
    static let formatosAvatarPermitidos = ["jpg", "jpeg", "png", "webp"]
}
