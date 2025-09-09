import Foundation

enum TrainingRoutineScheduler {
    /// Programa ejercicios por días de semana durante `weeks` semanas (1=Dom,...,7=Sáb).
    static func scheduleRoutine(
        startFrom: Date,
        weekdays: Set<Int>,
        weeks: Int,
        ejercicios: [Ejercicio]
    ) async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Lunes

        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: startFrom)?.start else { return }

        var targetDates: [Date] = []
        for w in 0..<weeks {
            guard let base = calendar.date(byAdding: .weekOfYear, value: w, to: weekStart) else { continue }
            for wd in weekdays {
                if let date = nextDate(inWeekStartingAt: base, weekday: wd, calendar: calendar) {
                    // En la primera semana, no programar antes de startFrom
                    if w == 0 && startOfDay(date, calendar) < startOfDay(startFrom, calendar) { continue }
                    targetDates.append(date)
                }
            }
        }

        for day in targetDates {
            try await SupabaseService.shared.upsertPlan(fecha: day, ejercicios: ejercicios)
        }
    }

    /// Aplica ejercicios exactamente en las fechas indicadas (sin recurrencia).
    static func scheduleOnExactDates(
        dates: Set<Date>,
        ejercicios: [Ejercicio]
    ) async throws {
        let cal = Calendar(identifier: .gregorian)
        let normalized = dates.map { cal.startOfDay(for: $0) }.sorted()
        for day in normalized {
            try await SupabaseService.shared.upsertPlan(fecha: day, ejercicios: ejercicios)
        }
    }

    // MARK: - Helpers
    /// Devuelve el día `weekday` (1=Dom...7=Sáb) dentro de la semana que empieza en `weekStart` (lunes-based).
    private static func nextDate(inWeekStartingAt weekStart: Date, weekday: Int, calendar: Calendar) -> Date? {
        // Mapeo: 2->0 (L), 3->1, 4->2, 5->3, 6->4, 7->5, 1->6 (D)
        let offsetFromMonday: Int = {
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

    @inline(__always)
    private static func startOfDay(_ date: Date, _ calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }
}
