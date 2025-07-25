import Foundation
import Supabase

// MARK: - Modelos

struct Logro: Identifiable, Decodable {
    let id: UUID
    let titulo: String
    let descripcion: String
    let icono_nombre: String
    let orden: Int
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
}

struct NuevoLogroUsuario: Encodable {
    let logro_id: UUID
    let autor_id: UUID
}

// MARK: - Identificadores fijos para logros

enum LogrosID {
    static let primerEntreno = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let cincoEntrenos = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    static let milKg = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
}

// MARK: - Obtener logros

extension SupabaseService {
    func fetchLogrosCompletos() async throws -> [LogroConEstado] {
        let userID = try await client.auth.session.user.id.uuidString

        // 1. Logros definidos
        let logrosResponse = try await client
            .from("logros")
            .select()
            .order("orden", ascending: true)
            .execute()

        let logros = try logrosResponse.decodedList(to: Logro.self)

        // 2. Logros desbloqueados por el usuario
        let desbloqueadosResponse = try await client
            .from("logros_usuario")
            .select("logro_id, conseguido_en")
            .eq("autor_id", value: userID)
            .execute()

        let desbloqueados = try desbloqueadosResponse.decodedList(to: LogroUsuario.self)
        let logrosDesbloqueados = Dictionary(uniqueKeysWithValues: desbloqueados.map { ($0.logro_id, $0.conseguido_en) })

        // 3. Mezcla
        return logros.map { logro in
            LogroConEstado(
                id: logro.id,
                titulo: logro.titulo,
                descripcion: logro.descripcion,
                icono_nombre: logro.icono_nombre,
                desbloqueado: logrosDesbloqueados[logro.id] != nil,
                fecha: logrosDesbloqueados[logro.id]
            )
        }
    }
}

extension SupabaseService {
    func desbloquearLogro(logroID: UUID) async throws {
        let userID = try await client.auth.session.user.id

        let nuevo = NuevoLogroUsuario(logro_id: logroID, autor_id: userID)

        do {
            _ = try await client
                .from("logros_usuario")
                .insert([nuevo])
                .execute()

            print("✅ Logro desbloqueado correctamente")
        } catch {
            if let postgrestError = error as? PostgrestError,
               postgrestError.message.contains("duplicate key value") {
                print("ℹ️ El logro ya estaba desbloqueado")
            } else {
                throw error
            }
        }
    }
}

extension SupabaseService {
    func analizarYDesbloquearLogros() async {
        do {
            let posts = try await fetchPosts()
            guard !posts.isEmpty else { return }

            let entrenamientos = posts.flatMap { $0.contenido }

            let totalEntrenamientos = posts.count
            let totalKg = entrenamientos.reduce(0.0) { result, ejercicio in
                result + ejercicio.totalPeso
            }

            if totalEntrenamientos >= 1 {
                try? await desbloquearLogro(logroID: LogrosID.primerEntreno)
            }

            if totalEntrenamientos >= 5 {
                try? await desbloquearLogro(logroID: LogrosID.cincoEntrenos)
            }

            if totalKg >= 1000 {
                try? await desbloquearLogro(logroID: LogrosID.milKg)
            }

            print("✅ Análisis de logros completado")
        } catch {
            print("❌ Error al analizar logros:", error)
        }
    }
}
