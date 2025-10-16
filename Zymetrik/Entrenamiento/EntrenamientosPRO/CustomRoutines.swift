//
//  CustomRoutinesLibrary.swift
//  YourAppName
//
//  Created by Developer on 2025-10-16.
//

import Foundation

/// RoutineDifficulty enum serves as a UI helper mirroring NivelEntrenamiento cases for labeling convenience.
/// The actual training level logic remains in `NivelEntrenamiento`.
enum RoutineDifficulty: String, CaseIterable {
    case principiante
    case intermedio
    case avanzado
}

/// Represents a user-authored training routine definition with weekly exercise plan by names.
struct RoutineDefinition: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let nivel: NivelEntrenamiento
    let diasPorSemana: Int
    /// Weekly plan keyed by weekday integer (1=Domingo ... 7=Sábado) to list of exercise names.
    let weeklyPlanNames: [Int: [String]]
    
    /// Maps the `weeklyPlanNames` to actual Ejercicio instances from the given catalog.
    /// Exercise name matching is case-insensitive. Unknown names are skipped.
    /// - Parameter catalog: Array of Ejercicio instances to match against.
    /// - Returns: Dictionary keyed by weekday integer to array of matched Ejercicio.
    func mapToEjercicios(from catalog: [Ejercicio]) -> [Int: [Ejercicio]] {
        var result: [Int: [Ejercicio]] = [:]
        
        // Create a lookup dictionary for case-insensitive name matching
        let catalogLookup = Dictionary(grouping: catalog, by: { $0.nombre.lowercased() })
        
        for (day, exerciseNames) in weeklyPlanNames {
            var matchedEjercicios: [Ejercicio] = []
            for name in exerciseNames {
                let lowerName = name.lowercased()
                if let ejercicios = catalogLookup[lowerName] {
                    // Take first match if multiple found
                    if let ejercicio = ejercicios.first {
                        matchedEjercicios.append(ejercicio)
                    }
                }
            }
            if !matchedEjercicios.isEmpty {
                result[day] = matchedEjercicios
            }
        }
        
        return result
    }
}

/// Container for developer-editable custom routines library.
enum CustomRoutinesLibrary {
    
    /// Array of predefined example user routines.
    static let all: [RoutineDefinition] = [
        
        RoutineDefinition(
            id: UUID(),
            title: "Fuerza 3x Básica",
            subtitle: "Compuestos L, X, V; descanso resto",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: ["Sentadilla", "Press banca", "Peso muerto"],         // Lunes
                4: ["Sentadilla", "Remo con barra", "Press militar"],    // Miércoles
                6: ["Peso muerto", "Dominadas", "Press banca"]           // Viernes
            ]
        ),
        
        RoutineDefinition(
            id: UUID(),
            title: "Torso/Pierna 4x",
            subtitle: "Torso M/J y Pierna L/V; descanso resto",
            nivel: .avanzado,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: ["Sentadilla", "Peso muerto", "Elevaciones de talón"],    // Lunes - Pierna
                3: ["Press banca", "Remo con barra", "Press militar"],       // Martes - Torso
                5: ["Sentadilla", "Peso muerto", "Elevaciones de talón"],    // Jueves - Pierna
                6: ["Press banca", "Dominadas", "Press militar"]             // Viernes - Torso
            ]
        ),
        
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 2x",
            subtitle: "Martes y Sábado",
            nivel: .principiante,
            diasPorSemana: 2,
            weeklyPlanNames: [
                3: ["Sentadilla", "Press banca", "Dominadas"],      // Martes
                6: ["Peso muerto", "Remo con barra", "Press militar"] // Sábado
            ]
        )
    ]
}
