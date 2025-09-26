import Foundation

/// Motor sencillo que:
/// 1) filtra el catálogo según nivel/foco
/// 2) reparte ejercicios en los días seleccionados
/// 3) aplica al calendario (TrainingPlanStore)
enum TemplateEngineLite {

    /// Construye un preview semana (1..7) en base a catálogo y configuración
    static func buildPreview(
        catalog: [Ejercicio],
        nivel: NivelEntrenamiento,
        foco: FocoPlan,
        dias: Set<Int>,              // 1..7
        diasPorSemana: Int
    ) -> [Int: [Ejercicio]] {

        // 1) Filtrado base por foco
        var fuerza = catalog.filter { $0.tipo.lowercased().contains("gimnasio") || $0.categoria.lowercased().contains("fuerza") }
        var cardio = catalog.filter { $0.tipo.lowercased().contains("cardio") || $0.categoria.lowercased().contains("cardio") }

        // Heurística por nombre si la taxonomía no está clara
        if fuerza.isEmpty {
            fuerza = catalog.filter { nameMatch($0.nombre, ["press","squat","peso muerto","remo","dominada","hombro","banco","curl","tríceps"]) }
        }
        if cardio.isEmpty {
            cardio = catalog.filter { nameMatch($0.nombre, ["carrera","run","bike","bici","remo","elíptica","caminata","saltar","burpee"]) }
        }

        // 2) Volumen objetivo por día según nivel/foco
        let porDia = volEjercicios(nivel: nivel, foco: foco)

        // 3) Selectores rotatorios
        let pickFuerza = makePicker(from: fuerza)
        let pickCardio = makePicker(from: cardio)

        // 4) Reparto por días elegidos
        var result: [Int: [Ejercicio]] = [:]
        let selected = orderedWeekdays(from: dias)

        for (index, weekday) in selected.enumerated() {
            var bucket: [Ejercicio] = []

            switch foco {
            case .fuerza:
                bucket.append(contentsOf: pickFuerza.take(porDia.fuerza))
            case .cardio:
                bucket.append(contentsOf: pickCardio.take(porDia.cardio))
            case .hibrido:
                // alterna fuerza/cardio
                if index % 2 == 0 {
                    bucket.append(contentsOf: pickFuerza.take(porDia.fuerza))
                } else {
                    bucket.append(contentsOf: pickCardio.take(porDia.cardio))
                }
            }

            result[weekday] = bucket
        }

        // Relleno si el usuario pidió más días/semana de los seleccionados
        if result.count < diasPorSemana {
            let all = Set(1...7)
            let remaining = orderedWeekdays(from: all.subtracting(dias))
            var i = 0
            while result.count < diasPorSemana, i < remaining.count {
                let wd = remaining[i]
                var bucket: [Ejercicio] = []
                switch foco {
                case .fuerza:
                    bucket = pickFuerza.take(porDia.fuerza)
                case .cardio:
                    bucket = pickCardio.take(porDia.cardio)
                case .hibrido:
                    bucket = (result.count % 2 == 0)
                        ? pickFuerza.take(porDia.fuerza)
                        : pickCardio.take(porDia.cardio)
                }
                result[wd] = bucket
                i += 1
            }
        }

        return result
    }

    /// Aplica la rutina a N semanas desde startDate
    @MainActor
    static func apply(
        preview: [Int: [Ejercicio]],
        startDate: Date,
        weeks: Int,
        planStore: TrainingPlanStore
    ) -> [Date] {

        var affected: [Date] = []
        let cal = Calendar(identifier: .gregorian)

        for w in 0..<weeks {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: w, to: startOfWeek(from: startDate)) else { continue }
            for (weekday, ejercicios) in preview {
                if let date = dateForWeekday(weekday, inWeekStartingAt: weekStart) {
                    planStore.add(ejercicios: ejercicios, para: date)
                    affected.append(date)
                }
            }
        }
        return affected
    }

    // MARK: - Helpers de volumen y fechas

    private static func volEjercicios(nivel: NivelEntrenamiento, foco: FocoPlan) -> (fuerza: Int, cardio: Int) {
        switch (nivel, foco) {
        case (.principiante, .fuerza): return (3, 0)
        case (.intermedio, .fuerza):  return (4, 0)
        case (.avanzado, .fuerza):    return (5, 0)

        case (.principiante, .cardio): return (0, 1)
        case (.intermedio, .cardio):   return (0, 2)
        case (.avanzado, .cardio):     return (0, 3)

        case (.principiante, .hibrido): return (3, 1)
        case (.intermedio, .hibrido):   return (4, 2)
        case (.avanzado, .hibrido):     return (5, 2)
        }
    }

    private static func orderedWeekdays(from set: Set<Int>) -> [Int] {
        let order = [2,3,4,5,6,7,1] // L..D (1=Dom..7=Sáb)
        return order.filter { set.contains($0) }
    }

    private static func startOfWeek(from date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)!.start
    }

    private static func dateForWeekday(_ weekday: Int, inWeekStartingAt start: Date) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        // weekday: 1..7 (Dom..Sáb)
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: i, to: start),
               cal.component(.weekday, from: d) == weekday {
                return d
            }
        }
        return nil
    }

    // MARK: - Picker rotatorio sin repeticiones

    private final class ExercisePicker {
        private var pool: [Ejercicio]
        private var idx = 0
        init(list: [Ejercicio]) {
            self.pool = list.shuffled()
        }
        func take(_ n: Int) -> [Ejercicio] {
            guard !pool.isEmpty, n > 0 else { return [] }
            var out: [Ejercicio] = []
            for _ in 0..<n {
                if idx >= pool.count { idx = 0; pool.shuffle() }
                out.append(pool[idx])
                idx += 1
            }
            return out
        }
    }

    private static func makePicker(from list: [Ejercicio]) -> ExercisePicker {
        ExercisePicker(list: list)
    }

    // MARK: - Heurística por nombre

    private static func nameMatch(_ name: String, _ keys: [String]) -> Bool {
        let low = name.lowercased()
        return keys.contains(where: { low.contains($0.lowercased()) })
    }
}
