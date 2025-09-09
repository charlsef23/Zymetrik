//
//  FuncionesLogros.swift
//  Zymetrik
//
//  Extensiones de SupabaseService para logros:
//  - fetchLogrosCompletos()
//  - desbloquearLogro(logroID:) -> Bool
//  - analizarYDesbloquearLogros() -> [UUID]
//

import Foundation
import Supabase

// MARK: - Cargar lista de logros con estado del usuario
extension SupabaseService {
    /// Devuelve todos los logros con su estado (desbloqueado/pendiente) para el usuario actual.
    func fetchLogrosCompletos() async throws -> [LogroConEstado] {
        let userID = try await client.auth.session.user.id.uuidString

        // 1) Logros definidos
        let logrosResponse = try await client
            .from("logros")
            .select()
            .order("orden", ascending: true)
            .execute()

        let logros = try logrosResponse.decodedList(to: Logro.self)

        // 2) Logros del usuario
        let desbloqueadosResponse = try await client
            .from("logros_usuario")
            .select("logro_id, conseguido_en")
            .eq("autor_id", value: userID)
            .execute()

        let desbloqueados = try desbloqueadosResponse.decodedList(to: LogroUsuario.self)
        let mapaDesbloqueados = Dictionary(
            uniqueKeysWithValues: desbloqueados.map { ($0.logro_id, $0.conseguido_en) }
        )

        // 3) Mezcla
        return logros.map { logro in
            LogroConEstado(
                id: logro.id,
                titulo: logro.titulo,
                descripcion: logro.descripcion,
                icono_nombre: logro.icono_nombre,
                desbloqueado: mapaDesbloqueados[logro.id] != nil,
                fecha: mapaDesbloqueados[logro.id],
                color: logro.color
            )
        }
    }
}

// MARK: - Insertar (si no existe) un logro desbloqueado para el usuario actual
extension SupabaseService {
    /// Inserta el logro en `logros_usuario` si no existía.
    /// - Returns: `true` si se insertó (nuevo); `false` si ya estaba desbloqueado.
    @discardableResult
    func desbloquearLogro(logroID: UUID) async throws -> Bool {
        let userID = try await client.auth.session.user.id
        let nuevo = NuevoLogroUsuario(logro_id: logroID, autor_id: userID)

        do {
            _ = try await client
                .from("logros_usuario")
                .insert([nuevo])
                .execute()
            print("✅ Logro \(logroID) desbloqueado (nuevo)")
            return true
        } catch {
            if let e = error as? PostgrestError {
                // Cubre variantes típicas de violación de unicidad/duplicado
                if e.message.localizedCaseInsensitiveContains("duplicate")
                    || e.message.localizedCaseInsensitiveContains("already exists")
                    || (e.hint?.localizedCaseInsensitiveContains("already exists") ?? false) {
                    print("ℹ️ Logro \(logroID) ya estaba desbloqueado")
                    return false
                }
            }
            throw error
        }
    }
}

// MARK: - Analizar hitos del usuario y devolver los logros recién desbloqueados
extension SupabaseService {
    /// Analiza los posts del usuario y desbloquea logros. Devuelve los IDs desbloqueados en esta pasada.
    @discardableResult
    func analizarYDesbloquearLogros() async -> [UUID] {
        var nuevos: [UUID] = []

        do {
            let posts = try await fetchPosts()
            guard !posts.isEmpty else { return [] }

            // Suponiendo que Post.contenido es una colección de ejercicios con totalPeso
            let entrenamientos = posts.flatMap { $0.contenido }

            let totalEntrenamientos = posts.count
            let totalKg = entrenamientos.reduce(0.0) { $0 + $1.totalPeso }

            // 1) Primer entreno
            if totalEntrenamientos >= 1,
               (try? await desbloquearLogro(logroID: LogrosID.primerEntreno)) == true {
                nuevos.append(LogrosID.primerEntreno)
            }

            // 2) Cinco entrenos
            if totalEntrenamientos >= 5,
               (try? await desbloquearLogro(logroID: LogrosID.cincoEntrenos)) == true {
                nuevos.append(LogrosID.cincoEntrenos)
            }

            // 3) Mil Kg acumulados
            if totalKg >= 1000,
               (try? await desbloquearLogro(logroID: LogrosID.milKg)) == true {
                nuevos.append(LogrosID.milKg)
            }

            print("✅ Análisis de logros completado. Nuevos: \(nuevos)")
            return nuevos
        } catch {
            print("❌ Error al analizar logros:", error)
            return []
        }
    }
}

