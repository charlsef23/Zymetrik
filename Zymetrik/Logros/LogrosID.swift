import Foundation

enum LogrosID {
    // Entrenamientos
    static let primerEntreno  = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
    static let cincoEntrenos  = UUID(uuidString: "6ba7b811-9dad-11d1-80b4-00c04fd430c8")!
    static let milKg          = UUID(uuidString: "6ba7b812-9dad-11d1-80b4-00c04fd430c8")!
    static let fuerzaBruta    = UUID(uuidString: "6ba7b813-9dad-11d1-80b4-00c04fd430c8")!
    static let atletaCompleto = UUID(uuidString: "6ba7b814-9dad-11d1-80b4-00c04fd430c8")!

    // Sociales
    static let primerPost     = UUID(uuidString: "6ba7b815-9dad-11d1-80b4-00c04fd430c8")!
    static let sociable       = UUID(uuidString: "6ba7b816-9dad-11d1-80b4-00c04fd430c8")!
    static let popular        = UUID(uuidString: "6ba7b817-9dad-11d1-80b4-00c04fd430c8")!
    static let influencer     = UUID(uuidString: "6ba7b818-9dad-11d1-80b4-00c04fd430c8")!
    static let comentarista   = UUID(uuidString: "6ba7b819-9dad-11d1-80b4-00c04fd430c8")!

    // Consistencia
    static let constante      = UUID(uuidString: "6ba7b81a-9dad-11d1-80b4-00c04fd430c8")!
    static let veterano       = UUID(uuidString: "6ba7b81b-9dad-11d1-80b4-00c04fd430c8")!
    static let maestro        = UUID(uuidString: "6ba7b81c-9dad-11d1-80b4-00c04fd430c8")!
    static let imparable      = UUID(uuidString: "6ba7b81d-9dad-11d1-80b4-00c04fd430c8")!
    static let leyenda        = UUID(uuidString: "6ba7b81e-9dad-11d1-80b4-00c04fd430c8")!

    // Especiales
    static let madrugador     = UUID(uuidString: "6ba7b81f-9dad-11d1-80b4-00c04fd430c8")!
    static let nocturno       = UUID(uuidString: "6ba7b820-9dad-11d1-80b4-00c04fd430c8")!
    static let motivador      = UUID(uuidString: "6ba7b821-9dad-11d1-80b4-00c04fd430c8")!
}

// MARK: - Info

extension LogrosID {
    static func getLogroInfo(for id: UUID) -> (titulo: String, descripcion: String, categoria: String, dificultad: String, color: String, icono: String)? {
        switch id {
        case primerEntreno:
            return ("Primer Entrenamiento", "Completa tu primer entrenamiento en la aplicación", "entrenamiento", "principiante", "#4CAF50", "dumbbell.fill")

        case cincoEntrenos:
            return ("5 Entrenamientos", "Completa 5 entrenamientos exitosamente", "entrenamiento", "principiante", "#FF9800", "flame.fill")

        case milKg:
            return ("Levanta 1000kg", "Levanta un total de 1000kg en todos tus entrenamientos", "entrenamiento", "intermedio", "#FFD700", "trophy.fill")

        case fuerzaBruta:
            return ("Fuerza Bruta", "Levanta un total de 5000kg", "entrenamiento", "avanzado", "#8B0000", "hammer.fill")

        case atletaCompleto:
            return ("Atleta Completo", "Realiza ejercicios de 5 categorías diferentes", "entrenamiento", "intermedio", "#9C27B0", "person.fill.checkmark")

        case primerPost:
            return ("Primer Post", "Publica tu primer entrenamiento en la comunidad", "social", "principiante", "#2196F3", "camera.fill")

        case sociable:
            return ("Sociable", "Sigue a 10 personas en la comunidad", "social", "intermedio", "#9C27B0", "person.2.fill")

        case popular:
            return ("Popular", "Recibe 100 likes en total en tus publicaciones", "social", "intermedio", "#E91E63", "heart.fill")

        case influencer:
            return ("Influencer", "Recibe 500 likes en total", "social", "avanzado", "#FF1493", "star.circle.fill")

        case comentarista:
            return ("Comentarista", "Escribe 50 comentarios en posts", "social", "intermedio", "#00CED1", "message.fill")

        case constante:
            return ("Constante", "Entrena 7 días consecutivos", "consistencia", "intermedio", "#FF5722", "calendar.badge.clock")

        case veterano:
            return ("Veterano", "Lleva 30 días usando la aplicación", "consistencia", "intermedio", "#795548", "star.fill")

        case maestro:
            return ("Maestro", "Completa 100 entrenamientos", "consistencia", "experto", "#9E9E9E", "crown.fill")

        case imparable:
            // 👇 corregido: "descripcion" sin tilde
            return ("Imparable", "Entrena 30 días consecutivos", "consistencia", "avanzado", "#FFD700", "bolt.fill")

        case leyenda:
            return ("Leyenda", "Completa 365 entrenamientos (uno por día)", "consistencia", "experto", "#800080", "laurel.leading")

        case madrugador:
            return ("Madrugador", "Entrena antes de las 7 AM por 10 días", "especial", "intermedio", "#FF8C00", "sunrise.fill")

        case nocturno:
            return ("Nocturno", "Entrena después de las 10 PM por 10 días", "especial", "intermedio", "#191970", "moon.stars.fill")

        case motivador:
            return ("Motivador", "Tus posts reciben un promedio de 10+ likes", "especial", "avanzado", "#32CD32", "hands.clap.fill")

        default:
            return nil
        }
    }

    static var allIDs: [UUID] {
        [
            // Entrenamientos
            primerEntreno, cincoEntrenos, milKg, fuerzaBruta, atletaCompleto,
            // Sociales
            primerPost, sociable, popular, influencer, comentarista,
            // Consistencia
            constante, veterano, maestro, imparable, leyenda,
            // Especiales
            madrugador, nocturno, motivador
        ]
    }

    // Utilidades

    static func createTestLogro(id: UUID, desbloqueado: Bool = false) -> LogroConEstado? {
        guard let info = getLogroInfo(for: id) else { return nil }
        return LogroConEstado(
            id: id,
            titulo: info.titulo,
            descripcion: info.descripcion,
            icono_nombre: info.icono,
            desbloqueado: desbloqueado,
            fecha: desbloqueado ? Date() : nil,
            color: info.color
        )
    }

    static func validateAllUUIDs() -> Bool {
        allIDs.allSatisfy { $0.uuidString.count == 36 && $0.uuidString.contains("-") }
    }
}
