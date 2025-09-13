import Foundation
import SwiftUI
import Supabase

@MainActor
final class TrainingPlanStore: ObservableObject {
    /// Clave "yyyy-MM-dd" (LOCAL) -> ejercicios del día
    @Published var ejerciciosPorDia: [String: [Ejercicio]] = [:]

    /// Formateador de clave por día en ZONA LOCAL
    private let df: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current            // 👈 LOCAL
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    // MARK: - API pública

    func ejercicios(en fecha: Date) -> [Ejercicio] {
        ejerciciosPorDia[key(fecha)] ?? []
    }

    /// Reemplaza los ejercicios del día (persiste) y actualiza cache
    func set(ejercicios: [Ejercicio], para fecha: Date) {
        Task {
            do {
                try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: ejercicios)
                self.ejerciciosPorDia[self.key(fecha)] = ejercicios
            } catch {
                print("❌ set(ejercicios) error:", error)
            }
        }
    }

    /// Añade (merge sin duplicar por id) y persiste
    func add(ejercicios nuevos: [Ejercicio], para fecha: Date) {
        let k = key(fecha)
        var current = ejerciciosPorDia[k] ?? []
        let existingIDs = Set(current.map(\.id))
        let toAppend = nuevos.filter { !existingIDs.contains($0.id) }
        guard !toAppend.isEmpty else { return }
        current.append(contentsOf: toAppend)
        ejerciciosPorDia[k] = current

        Task {
            do {
                try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: current)
            } catch {
                print("❌ add(ejercicios) error:", error)
            }
        }
    }

    /// Elimina un ejercicio por id y persiste
    func remove(ejercicioID: UUID, de fecha: Date) {
        let k = key(fecha)
        var current = ejerciciosPorDia[k] ?? []
        current.removeAll { $0.id == ejercicioID }
        ejerciciosPorDia[k] = current

        Task {
            do {
                try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: current)
            } catch {
                print("❌ remove(ejercicio) error:", error)
            }
        }
    }

    /// Refresca un día concreto desde Supabase
    func refresh(day fecha: Date) {
        Task {
            do {
                let items = try await SupabaseService.shared.fetchPlan(fecha: fecha)
                self.ejerciciosPorDia[self.key(fecha)] = items
            } catch {
                print("ℹ️ refresh(day) sin datos o error:", error)
                self.ejerciciosPorDia[self.key(fecha)] = []
            }
        }
    }

    /// Refresca varios días (secuencial, compatible)
    func refresh(days fechas: Set<Date>) {
        Task {
            var snapshot: [(String, [Ejercicio])] = []
            for d in fechas {
                do {
                    let items = try await SupabaseService.shared.fetchPlan(fecha: d)
                    snapshot.append((self.key(d), items))
                } catch {
                    snapshot.append((self.key(d), []))
                }
            }
            for (k, items) in snapshot {
                self.ejerciciosPorDia[k] = items
            }
        }
    }

    /// Opcional: precarga la semana visible
    func preloadWeek(around fecha: Date) {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2
        guard let start = cal.dateInterval(of: .weekOfYear, for: fecha)?.start else { return }
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        refresh(days: Set(days.map { cal.startOfDay(for: $0) }))
    }

    // MARK: - Helpers

    /// Clave LOCAL "yyyy-MM-dd" para la fecha
    private func key(_ fecha: Date) -> String {
        let cal = Calendar.current                      // 👈 LOCAL
        let comps = cal.dateComponents([.year, .month, .day], from: fecha)
        let localDay = cal.date(from: comps)!           // 00:00 local
        return df.string(from: localDay)                // "yyyy-MM-dd" local
    }
}
