import Foundation

enum TrainingRoutineScheduler {
    /// Programa ejercicios en las próximas `weeks` semanas en los días indicados (weekdays: 1=Dom, 2=Lun,...,7=Sáb),
    /// empezando desde `startFrom` (se usa la semana de esa fecha como base).
    static func scheduleRoutine(
        startFrom: Date,
        weekdays: Set<Int>,
        weeks: Int,
        ejercicios: [Ejercicio]
    ) async throws {
        let cal = Calendar(identifier: .gregorian)
        // Normalizamos a inicio de la semana de startFrom (lunes como primer día)
        var calendar = cal
        calendar.firstWeekday = 2

        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: startFrom)?.start else {
            return
        }

        // Generamos las fechas objetivo
        var targetDates: [Date] = []
        for w in 0..<weeks {
            guard let base = calendar.date(byAdding: .weekOfYear, value: w, to: weekStart) else { continue }
            for wd in weekdays {
                if let date = nextDate(inWeekStartingAt: base, weekday: wd, calendar: calendar) {
                    targetDates.append(date)
                }
            }
        }

        // Upsert para cada fecha (usa tu SupabaseService existente)
        for day in targetDates {
            try await SupabaseService.shared.upsertPlan(fecha: day, ejercicios: ejercicios)
        }
    }

    /// Devuelve la fecha dentro de esa semana que corresponde al `weekday` (1=Dom,...,7=Sáb)
    private static func nextDate(inWeekStartingAt weekStart: Date, weekday: Int, calendar: Calendar) -> Date? {
        // weekStart ya es lunes; transformamos a 1..7
        // Si weekday==2(Lunes), es weekStart + 0 días; si 3, +1; ...; si 1(Domingo), +6
        let offsetFromMonday: Int = {
            // Mapeo: 2->0, 3->1, 4->2, 5->3, 6->4, 7->5, 1->6
            switch weekday {
            case 2: return 0
            case 3: return 1
            case 4: return 2
            case 5: return 3
            case 6: return 4
            case 7: return 5
            case 1: return 6
            default: return 0
            }
        }()
        return calendar.date(byAdding: .day, value: offsetFromMonday, to: weekStart)
    }
}
