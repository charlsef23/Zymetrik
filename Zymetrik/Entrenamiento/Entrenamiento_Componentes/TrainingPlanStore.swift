import Foundation
import Combine

@MainActor
final class TrainingPlanStore: ObservableObject {
    @Published private(set) var ejerciciosPorDia: [String: [Ejercicio]] = [:] // clave = "yyyy-MM-dd"

    private let storageKey = "training.plan.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    // MARK: - API pública

    func ejercicios(en fecha: Date) -> [Ejercicio] {
        ejerciciosPorDia[fecha.keyDate()] ?? []
    }

    func set(ejercicios: [Ejercicio], para fecha: Date) {
        ejerciciosPorDia[fecha.keyDate()] = ejercicios
        save()
        Task { await syncSupabase(fecha: fecha, ejercicios: ejercicios) }
    }

    func add(ejercicios nuevos: [Ejercicio], para fecha: Date) {
        let key = fecha.keyDate()
        var actuales = ejerciciosPorDia[key] ?? []
        // Evita duplicados por id
        let idsActuales = Set(actuales.map(\.id))
        let filtrados = nuevos.filter { !idsActuales.contains($0.id) }
        actuales.append(contentsOf: filtrados)
        ejerciciosPorDia[key] = actuales
        save()
        Task { await syncSupabase(fecha: fecha, ejercicios: actuales) }
    }

    func remove(ejercicioID: UUID, de fecha: Date) {
        let key = fecha.keyDate()
        ejerciciosPorDia[key]?.removeAll { $0.id == ejercicioID }
        if ejerciciosPorDia[key]?.isEmpty == true { ejerciciosPorDia[key] = nil }
        save()
        Task { await syncSupabase(fecha: fecha, ejercicios: ejerciciosPorDia[key] ?? []) }
    }

    // MARK: - Persistencia local (UserDefaults simple)

    private func save() {
        do {
            let data = try encoder.encode(ejerciciosPorDia)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Error guardando plan local:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            ejerciciosPorDia = try decoder.decode([String: [Ejercicio]].self, from: data)
        } catch {
            print("❌ Error cargando plan local:", error)
        }
    }

    // MARK: - Sync Supabase (opcional pero recomendado)

    private func syncSupabase(fecha: Date, ejercicios: [Ejercicio]) async {
        do {
            try await SupabaseService.shared.upsertPlan(fecha: fecha, ejercicios: ejercicios)
        } catch {
            // No bloquea UX; queda en local
            print("⚠️ No se pudo sincronizar con Supabase:", error)
        }
    }
}

// Helpers de fecha
extension Date {
    func keyDate() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self.stripTime())
    }
}
