// Modelos_Logros.swift
import Foundation

// MARK: - Modelos
struct Logro: Identifiable, Decodable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let icono_nombre: String
    let orden: Int
    let color: String?
}


struct LogroUsuario: Decodable {
    let logro_id: UUID
    let conseguido_en: Date
}

struct LogroConEstado: Identifiable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let icono_nombre: String
    let desbloqueado: Bool
    let fecha: Date?
    let color: String?
}

struct NuevoLogroUsuario: Encodable {
    let logro_id: UUID
    let autor_id: UUID
}

// MARK: - Identificadores fijos para logros
enum LogrosID {
    static let primerEntreno = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let cincoEntrenos  = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    static let milKg          = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
}
