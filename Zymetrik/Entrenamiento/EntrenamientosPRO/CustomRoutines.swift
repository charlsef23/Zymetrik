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
        let catalogLookup = Dictionary(grouping: catalog, by: { $0.nombre.lowercased() })
        for (day, exerciseNames) in weeklyPlanNames {
            var matched: [Ejercicio] = []
            for name in exerciseNames {
                let key = name.lowercased()
                if let found = catalogLookup[key]?.first {
                    matched.append(found)
                }
            }
            if !matched.isEmpty { result[day] = matched }
        }
        return result
    }
}

/// Container for developer-editable custom routines library.
enum CustomRoutinesLibrary {
    
    /// Array of predefined example user routines.
    static let all: [RoutineDefinition] = [
        
        // MARK: - 2 días (Principiante) - Full Body
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 2 días",
            subtitle: "Sesiones completas con básicos + accesorios",
            nivel: .principiante,
            diasPorSemana: 2,
            weeklyPlanNames: [
                3: [ // Martes
                    "Sentadilla barra",
                    "Press de banca",
                    "Remo con barra",
                    "Elevaciones laterales",
                    "Curl bíceps mancuernas",
                    "Extensión tríceps polea",
                    "Crunch en máquina",
                    "Plancha abdominal"
                ],
                6: [ // Viernes
                    "Prensa",
                    "Press de pecho máquina",
                    "Remo polea baja",
                    "Press militar con mancuernas",
                    "Curl barra Z",
                    "Press francés",
                    "Abdominales banco",
                    "Rotación de torso en máquina"
                ]
            ]
        ),
        
        // MARK: - 3 días (Intermedio) - Full Body alternando énfasis
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 3 días",
            subtitle: "L-X-S con énfasis pierna/torso/mixto",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [ // Lunes - Pierna/Glúteo
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas con barra",
                    "Curl femoral sentado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie",
                    "Hip thrust",
                    "Crunch polea"
                ],
                4: [ // Miércoles - Torso Empuje/Tirón
                    "Press de banca",
                    "Press inclinado",
                    "Cruce poleas",
                    "Remo con barra",
                    "Jalón al pecho",
                    "Face Pull",
                    "Extensión tríceps polea",
                    "Curl martillo"
                ],
                6: [ // Viernes - Mixto + Core
                    "Peso muerto",
                    "Remo polea baja",
                    "Press de hombros máquina",
                    "Elevaciones laterales",
                    "Dominadas asistidas",
                    "Curl predicador ",
                    "Press francés",
                    "Plancha abdominal"
                ]
            ]
        ),
        
        // MARK: - 4 días (Intermedio) - Torso/Pierna
        RoutineDefinition(
            id: UUID(),
            title: "Torso/Pierna 4 días",
            subtitle: "Torso (M/J) + Pierna (L/V)",
            nivel: .intermedio,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: [ // Lunes - Pierna A
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas mancuernas",
                    "Curl femoral tumbado",
                    "Extensión cuádriceps",
                    "Elevación de talones sentado",
                    "Abductores máquina",
                    "Crunch en máquina"
                ],
                3: [ // Martes - Torso A
                    "Press de banca",
                    "Remo con barra",
                    "Press militar con barra",
                    "Dominadas",
                    "Aperturas máquina",
                    "Face Pull",
                    "Extensión tríceps banco",
                    "Curl barra Z"
                ],
                5: [ // Jueves - Pierna B (Glúteo)
                    "Hip thrust",
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Patada de glúteo",
                    "Curl femoral de pie unilateral",
                    "Tibia dorsi",
                    "Box jump",
                    "Abdominales banco"
                ],
                6: [ // Viernes - Torso B
                    "Press pecho declinado",
                    "Remo polea baja",
                    "Press militar con mancuernas",
                    "Jalón tras nuca",
                    "Crossover poleas",
                    "Pájaros",
                    "Press francés",
                    "Curl de bíceps en polea baja"
                ]
            ]
        ),
        
        // MARK: - 5 días (Intermedio/Avanzado) - Upper/Lower + Push/Pull + FullBody
        RoutineDefinition(
            id: UUID(),
            title: "Híbrida 5 días",
            subtitle: "Upper/Lower + Push/Pull + Full Body",
            nivel: .intermedio,
            diasPorSemana: 5,
            weeklyPlanNames: [
                2: [ // Lunes - Upper
                    "Press de banca",
                    "Remo con barra",
                    "Press militar con barra",
                    "Aperturas polea",
                    "Jalón al pecho",
                    "Elevaciones laterales",
                    "Extensión tras nuca",
                    "Curl concentrado"
                ],
                3: [ // Martes - Lower
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas con barra",
                    "Curl femoral sentado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie",
                    "Crunch polea"
                ],
                4: [ // Miércoles - Push
                    "Press inclinado",
                    "Press de pecho máquina",
                    "Pec deck",
                    "Press de hombros máquina",
                    "Elevaciones laterales",
                    "Extensión tríceps polea",
                    "Fondos asistidos"
                ],
                5: [ // Jueves - Pull
                    "Dominadas",
                    "Remo T máquina",
                    "Remo polea baja",
                    "Pull-over en maquina",
                    "Face Pull",
                    "Curl martillo",
                    "Curl invertido",
                    "Plancha abdominal"
                ],
                6: [ // Viernes - Full Body rápido
                    "Peso muerto",
                    "Press de banca",
                    "Remo mancuernas 1 mano",
                    "Press militar con mancuernas",
                    "Ball Slam",
                    "Burpee"
                ]
            ]
        ),
        
        // MARK: - 6 días (Avanzado) - Push/Pull/Legs x2
        RoutineDefinition(
            id: UUID(),
            title: "PPL 6 días",
            subtitle: "Push/Pull/Legs × 2 (Sáb. ligero)",
            nivel: .avanzado,
            diasPorSemana: 6,
            weeklyPlanNames: [
                2: [ // Lunes - Push A
                    "Press de banca",
                    "Press inclinado",
                    "Cruce poleas",
                    "Press militar con barra",
                    "Elevaciones laterales",
                    "Extensión tríceps polea",
                    "Press francés"
                ],
                3: [ // Martes - Pull A
                    "Dominadas",
                    "Remo con barra",
                    "Remo polea baja",
                    "Jalón al pecho",
                    "Face Pull",
                    "Curl barra Z",
                    "Curl bíceps máquina"
                ],
                4: [ // Miércoles - Legs A
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas mancuernas",
                    "Curl femoral tumbado",
                    "Extensión cuádriceps",
                    "Elevación de talones sentado",
                    "Crunch en máquina"
                ],
                5: [ // Jueves - Push B
                    "Press de pecho máquina",
                    "Press pecho declinado",
                    "Aperturas polea baja",
                    "Press militar con mancuernas",
                    "Pájaros",
                    "Fondos paralelas",
                    "Extensión tras nuca"
                ],
                6: [ // Viernes - Pull B
                    "Dominadas asistidas",
                    "Remo T máquina",
                    "Remo 1 mano polea",
                    "Pullover en polea",
                    "Jalón tras nuca",
                    "Curl predicador ",
                    "Curl concentrado"
                ],
                7: [ // Sábado - Legs B (Glúteo/Explosivo)
                    "Hip thrust",
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Patada de glúteo",
                    "Curl femoral de pie unilateral",
                    "Tibia dorsi",
                    "Box jump",
                    "Plancha abdominal"
                ]
            ]
        ),
        
        // MARK: - 7 días (Avanzado) - Split completo (Domingo movilidad/core)
        RoutineDefinition(
            id: UUID(),
            title: "Split 7 días",
            subtitle: "Rutina diaria con volumen distribuido",
            nivel: .avanzado,
            diasPorSemana: 7,
            weeklyPlanNames: [
                1: [ // Domingo - Core/Condición & movilidad ligera
                    "Plancha abdominal",
                    "Crunch en máquina",
                    "Abdominales banco",
                    "Rotación de torso en máquina",
                    "Ball Slam",
                    "Burpee"
                ],
                2: [ // Lunes - Pecho
                    "Press de banca",
                    "Press inclinado",
                    "Press pecho declinado",
                    "Pec deck",
                    "Crossover poleas",
                    "Aperturas máquina",
                    "Aperturas polea"
                ],
                3: [ // Martes - Espalda
                    "Peso muerto",
                    "Remo con barra",
                    "Remo polea baja",
                    "Remo convergente",
                    "Jalón al pecho",
                    "Pull-over en maquina",
                    "Face Pull"
                ],
                4: [ // Miércoles - Piernas (Cuádriceps)
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas con barra",
                    "Extensión cuádriceps",
                    "Curl pierna tumbado",
                    "Elevación de talones de pie",
                    "Tibia dorsi"
                ],
                5: [ // Jueves - Hombros
                    "Press militar con barra",
                    "Press de hombros máquina",
                    "Elevaciones laterales",
                    "Elevaciones laterales máquina",
                    "Elevaciones frontales polea",
                    "Elevaciones posteriores polea",
                    "Pájaros"
                ],
                6: [ // Viernes - Brazos
                    "Curl barra Z",
                    "Curl bíceps mancuernas",
                    "Curl bíceps 1 mano",
                    "Curl de bíceps en polea baja",
                    "Extensión tríceps polea",
                    "Extensión tras nuca",
                    "Fondos asistidos",
                    "Press francés"
                ],
                7: [ // Sábado - Piernas (Femoral/Glúteo)
                    "Sentadilla hack",
                    "Zancadas mancuernas",
                    "Hip thrust",
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Curl femoral sentado",
                    "Curl femoral de pie unilateral",
                    "Elevación de talones sentado",
                    "Abductores máquina"
                ]
            ]
        ),
        
        // MARK: - 3 días (Principiante) alternativo con asistencia
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 3 días (asistida)",
            subtitle: "Enfoque técnico con asistencia",
            nivel: .principiante,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [ // Lunes
                    "Prensa",
                    "Press de pecho máquina",
                    "Remo polea baja",
                    "Dominadas asistidas",
                    "Elevaciones laterales",
                    "Curl bíceps máquina",
                    "Extensión tríceps banco",
                    "Crunch polea"
                ],
                4: [ // Miércoles
                    "Sentadilla barra",
                    "Press de banca",
                    "Remo mancuernas 1 mano",
                    "Jalón al pecho",
                    "Press militar con mancuernas",
                    "Curl concentrado",
                    "Fondos asistidos",
                    "Plancha abdominal"
                ],
                6: [ // Viernes
                    "Zancadas con barra",
                    "Press inclinado",
                    "Remo 1 mano polea",
                    "Face Pull",
                    "Aperturas polea",
                    "Curl martillo",
                    "Extensión tras nuca",
                    "Abdominales banco"
                ]
            ]
        )
    ]
}
