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
        
        // ===== EXISTENTES =====
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
        ),
        
        // ===== NUEVAS RUTINAS =====
        // MARK: - 2 días (Principiante) - Máquinas
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 2 días (máquinas)",
            subtitle: "Orientada a máquinas para técnica y seguridad",
            nivel: .principiante,
            diasPorSemana: 2,
            weeklyPlanNames: [
                2: [ // Lunes
                    "Press de pecho máquina",
                    "Remo polea baja",
                    "Press de hombros máquina",
                    "Pec deck",
                    "Jalón al pecho",
                    "Curl bíceps máquina",
                    "Extensión tríceps polea",
                    "Crunch en máquina"
                ],
                5: [ // Jueves
                    "Prensa",
                    "Sentadilla hack",
                    "Curl femoral sentado",
                    "Extensión cuádriceps",
                    "Elevación de talones sentado",
                    "Abductores máquina",
                    "Plancha abdominal",
                    "Rotación de torso en máquina"
                ]
            ]
        ),
        
        // MARK: - 2 días (Intermedio) - Full Body rápida
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 2 días (rápida)",
            subtitle: "Circuito eficiente en 60′",
            nivel: .intermedio,
            diasPorSemana: 2,
            weeklyPlanNames: [
                3: [
                    "Sentadilla barra",
                    "Press de banca",
                    "Remo con barra",
                    "Press militar con barra",
                    "Curl barra Z",
                    "Press francés",
                    "Ball Slam",
                    "Plancha abdominal"
                ],
                6: [
                    "Prensa",
                    "Press inclinado",
                    "Remo polea baja",
                    "Press de hombros máquina",
                    "Curl martillo",
                    "Extensión tras nuca",
                    "Burpee",
                    "Crunch polea"
                ]
            ]
        ),
        
        // MARK: - 3 días (Intermedio) - Glúteo & Pierna
        RoutineDefinition(
            id: UUID(),
            title: "Glúteo & Pierna 3 días",
            subtitle: "Enfoque glúteo-femoral con core",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [
                    "Hip thrust",
                    "Prensa",
                    "Zancadas mancuernas",
                    "Curl femoral tumbado",
                    "Elevación de talones de pie",
                    "Crunch en máquina"
                ],
                4: [
                    "Sentadilla barra",
                    "Extensión cuádriceps",
                    "Curl femoral sentado",
                    "Abductores máquina",
                    "Tibia dorsi",
                    "Plancha abdominal"
                ],
                6: [
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Patada de glúteo",
                    "Curl femoral de pie unilateral",
                    "Box jump",
                    "Rotación de torso en máquina"
                ]
            ]
        ),
        
        // MARK: - 3 días (Intermedio) - Espalda fuerte
        RoutineDefinition(
            id: UUID(),
            title: "Espalda Fuerte 3 días",
            subtitle: "Tirón dominante + estabilidad escapular",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [
                    "Peso muerto",
                    "Remo con barra",
                    "Jalón al pecho",
                    "Face Pull",
                    "Remo mancuernas 1 mano",
                    "Crunch polea"
                ],
                4: [
                    "Dominadas",
                    "Remo T máquina",
                    "Remo polea baja",
                    "Pull-over en maquina",
                    "Curl invertido",
                    "Plancha abdominal"
                ],
                6: [
                    "Dominadas asistidas",
                    "Remo 1 mano polea",
                    "Remo convergente",
                    "Jalón tras nuca",
                    "Extension lumbar",
                    "Abdominales banco"
                ]
            ]
        ),
        
        // MARK: - 3 días (Intermedio) - Push Focus
        RoutineDefinition(
            id: UUID(),
            title: "Push 3 días",
            subtitle: "Pecho + Hombro + Tríceps",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [
                    "Press de banca",
                    "Press inclinado",
                    "Aperturas polea",
                    "Extensión tríceps polea",
                    "Press francés",
                    "Crunch en máquina"
                ],
                4: [
                    "Press de hombros máquina",
                    "Press militar con mancuernas",
                    "Elevaciones laterales",
                    "Pájaros",
                    "Extensión tras nuca",
                    "Plancha abdominal"
                ],
                6: [
                    "Press de pecho máquina",
                    "Pec deck",
                    "Crossover poleas",
                    "Fondos asistidos",
                    "Extensión tríceps banco",
                    "Abdominales banco"
                ]
            ]
        ),
        
        // MARK: - 4 días (Intermedio) - Upper/Lower Fuerza
        RoutineDefinition(
            id: UUID(),
            title: "Upper/Lower Fuerza 4 días",
            subtitle: "Compuestos pesados + accesorios clave",
            nivel: .intermedio,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: [ // Upper A
                    "Press de banca",
                    "Remo con barra",
                    "Press militar con barra",
                    "Curl barra Z",
                    "Press francés",
                    "Crunch polea"
                ],
                3: [ // Lower A
                    "Sentadilla barra",
                    "Prensa",
                    "Curl femoral tumbado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie",
                    "Plancha abdominal"
                ],
                5: [ // Upper B
                    "Press inclinado",
                    "Jalón al pecho",
                    "Remo polea baja",
                    "Curl martillo",
                    "Extensión tras nuca",
                    "Abdominales banco"
                ],
                6: [ // Lower B
                    "Peso muerto",
                    "Zancadas con barra",
                    "Curl femoral sentado",
                    "Tibia dorsi",
                    "Elevación de talones sentado",
                    "Rotación de torso en máquina"
                ]
            ]
        ),
        
        // MARK: - 4 días (Principiante) - Máquinas Torso/Pierna
        RoutineDefinition(
            id: UUID(),
            title: "Torso/Pierna 4 días (máquinas)",
            subtitle: "Aprendizaje seguro y estable",
            nivel: .principiante,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: [
                    "Prensa",
                    "Sentadilla hack",
                    "Extensión cuádriceps",
                    "Curl femoral sentado",
                    "Elevación de talones sentado",
                    "Crunch en máquina"
                ],
                3: [
                    "Press de pecho máquina",
                    "Remo polea baja",
                    "Press de hombros máquina",
                    "Pec deck",
                    "Jalón al pecho",
                    "Plancha abdominal"
                ],
                5: [
                    "Prensa",
                    "Zancadas mancuernas",
                    "Abductores máquina",
                    "Tibia dorsi",
                    "Elevación de talones de pie",
                    "Abdominales banco"
                ],
                6: [
                    "Press de pecho máquina",
                    "Remo T máquina",
                    "Jalón tras nuca",
                    "Elevaciones laterales máquina",
                    "Crossover poleas",
                    "Rotación de torso en máquina"
                ]
            ]
        ),
        
        // MARK: - 5 días (Intermedio) - Split Clásico
        RoutineDefinition(
            id: UUID(),
            title: "Split Clásico 5 días",
            subtitle: "Pecho, Espalda, Pierna, Hombro, Brazos",
            nivel: .intermedio,
            diasPorSemana: 5,
            weeklyPlanNames: [
                2: [ // Pecho
                    "Press de banca",
                    "Press inclinado",
                    "Pec deck",
                    "Aperturas polea",
                    "Crossover poleas",
                    "Crunch en máquina"
                ],
                3: [ // Espalda
                    "Peso muerto",
                    "Remo con barra",
                    "Remo polea baja",
                    "Jalón al pecho",
                    "Face Pull",
                    "Plancha abdominal"
                ],
                4: [ // Pierna
                    "Sentadilla barra",
                    "Prensa",
                    "Zancadas con barra",
                    "Curl femoral tumbado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie"
                ],
                5: [ // Hombro
                    "Press militar con barra",
                    "Press de hombros máquina",
                    "Elevaciones laterales",
                    "Elevaciones posteriores polea",
                    "Elevaciones frontales polea",
                    "Pájaros"
                ],
                6: [ // Brazos
                    "Curl barra Z",
                    "Curl bíceps mancuernas",
                    "Curl de bíceps en polea baja",
                    "Extensión tríceps polea",
                    "Extensión tras nuca",
                    "Press francés"
                ]
            ]
        ),
        
        // MARK: - 5 días (Avanzado) - PPL+Upper+Lower
        RoutineDefinition(
            id: UUID(),
            title: "PPL+Upper+Lower 5 días",
            subtitle: "Tirón/Empuje/Pierna + Upper + Lower",
            nivel: .avanzado,
            diasPorSemana: 5,
            weeklyPlanNames: [
                2: [ // Pull
                    "Dominadas",
                    "Remo con barra",
                    "Remo polea baja",
                    "Jalón al pecho",
                    "Face Pull",
                    "Curl martillo"
                ],
                3: [ // Push
                    "Press de banca",
                    "Press inclinado",
                    "Cruce poleas",
                    "Press militar con mancuernas",
                    "Extensión tríceps polea",
                    "Press francés"
                ],
                4: [ // Legs
                    "Sentadilla barra",
                    "Prensa",
                    "Curl femoral sentado",
                    "Extensión cuádriceps",
                    "Elevación de talones sentado",
                    "Tibia dorsi"
                ],
                5: [ // Upper
                    "Remo T máquina",
                    "Press de pecho máquina",
                    "Press de hombros máquina",
                    "Aperturas máquina",
                    "Curl barra Z",
                    "Extensión tras nuca"
                ],
                6: [ // Lower Glúteo
                    "Hip thrust",
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Patada de glúteo",
                    "Box jump",
                    "Plancha abdominal"
                ]
            ]
        ),
        
        // MARK: - 6 días (Avanzado) - Volumen Alto
        RoutineDefinition(
            id: UUID(),
            title: "Volumen Alto 6 días",
            subtitle: "Frecuencia 2 con accesorios dirigidos",
            nivel: .avanzado,
            diasPorSemana: 6,
            weeklyPlanNames: [
                2: [ // Pecho/Hombro
                    "Press de banca",
                    "Press inclinado",
                    "Aperturas polea",
                    "Press militar con barra",
                    "Elevaciones laterales",
                    "Pájaros"
                ],
                3: [ // Espalda
                    "Peso muerto",
                    "Remo con barra",
                    "Remo polea baja",
                    "Jalón al pecho",
                    "Face Pull",
                    "Pull-over en maquina"
                ],
                4: [ // Pierna A
                    "Sentadilla barra",
                    "Prensa",
                    "Curl femoral tumbado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie",
                    "Crunch polea"
                ],
                5: [ // Pecho/Tríceps
                    "Press de pecho máquina",
                    "Pec deck",
                    "Crossover poleas",
                    "Extensión tríceps polea",
                    "Extensión tras nuca",
                    "Press francés"
                ],
                6: [ // Espalda/Bíceps
                    "Dominadas",
                    "Remo T máquina",
                    "Remo mancuernas 1 mano",
                    "Curl barra Z",
                    "Curl concentrado",
                    "Curl invertido"
                ],
                7: [ // Pierna B (Glúteo/Core)
                    "Hip thrust",
                    "Hip thrust máquina",
                    "Extensión cadera",
                    "Curl femoral de pie unilateral",
                    "Tibia dorsi",
                    "Plancha abdominal"
                ]
            ]
        ),
        
        // MARK: - 6 días (Intermedio) - PPL Ligero Fin de Semana Off
        RoutineDefinition(
            id: UUID(),
            title: "PPL 6 días (fin de semana off Dom.)",
            subtitle: "De L a S, Domingo descanso/actividad ligera",
            nivel: .intermedio,
            diasPorSemana: 6,
            weeklyPlanNames: [
                2: [ "Press de banca", "Press inclinado", "Cruce poleas", "Press militar con barra", "Elevaciones laterales", "Extensión tríceps polea" ],
                3: [ "Dominadas", "Remo con barra", "Remo polea baja", "Jalón al pecho", "Face Pull", "Curl bíceps mancuernas" ],
                4: [ "Sentadilla barra", "Prensa", "Zancadas con barra", "Curl femoral sentado", "Extensión cuádriceps", "Elevación de talones de pie" ],
                5: [ "Press de pecho máquina", "Pec deck", "Aperturas máquina", "Press de hombros máquina", "Pájaros", "Press francés" ],
                6: [ "Dominadas asistidas", "Remo T máquina", "Remo 1 mano polea", "Pull-over en maquina", "Jalón tras nuca", "Curl barra Z" ],
                7: [ "Sentadilla hack", "Prensa", "Curl femoral tumbado", "Elevación de talones sentado", "Tibia dorsi", "Plancha abdominal" ]
            ]
        ),
        
        // MARK: - 7 días (Intermedio) - Acondicionamiento Diario
        RoutineDefinition(
            id: UUID(),
            title: "Acondicionamiento 7 días",
            subtitle: "Sesiones cortas + core cada día",
            nivel: .intermedio,
            diasPorSemana: 7,
            weeklyPlanNames: [
                1: [ "Plancha abdominal", "Crunch en máquina", "Rotación de torso en máquina", "Ball Slam" ],
                2: [ "Press de banca", "Aperturas polea", "Extensión tríceps polea", "Abdominales banco" ],
                3: [ "Remo con barra", "Jalón al pecho", "Curl barra Z", "Crunch polea" ],
                4: [ "Prensa", "Zancadas mancuernas", "Elevación de talones de pie", "Plancha abdominal" ],
                5: [ "Press de hombros máquina", "Elevaciones laterales", "Pájaros", "Abdominales banco" ],
                6: [ "Remo polea baja", "Face Pull", "Curl martillo", "Crunch en máquina" ],
                7: [ "Hip thrust", "Extensión cadera", "Tibia dorsi", "Rotación de torso en máquina" ]
            ]
        ),
        
        // MARK: - 4 días (Avanzado) - Glúteo & Pierna PRO
        RoutineDefinition(
            id: UUID(),
            title: "Glúteo & Pierna PRO 4 días",
            subtitle: "Alto enfoque en glúteo con potencia",
            nivel: .avanzado,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: [ "Hip thrust", "Sentadilla barra", "Curl femoral sentado", "Extensión cuádriceps", "Elevación de talones de pie", "Crunch en máquina" ],
                3: [ "Prensa", "Zancadas con barra", "Curl femoral tumbado", "Abductores máquina", "Tibia dorsi", "Plancha abdominal" ],
                5: [ "Hip thrust máquina", "Extensión cadera", "Patada de glúteo", "Curl femoral de pie unilateral", "Box jump", "Abdominales banco" ],
                6: [ "Sentadilla hack", "Prensa", "Elevación de talones sentado", "Extensión cuádriceps", "Curl pierna tumbado", "Rotación de torso en máquina" ]
            ]
        ),
        
        // MARK: - 5 días (Intermedio) - Hombro 3D
        RoutineDefinition(
            id: UUID(),
            title: "Hombro 3D 5 días",
            subtitle: "Deltoides anterior/lateral/posterior + estabilidad",
            nivel: .intermedio,
            diasPorSemana: 5,
            weeklyPlanNames: [
                2: [ "Press militar con barra", "Elevaciones laterales", "Elevaciones posteriores polea", "Pájaros", "Crunch polea" ],
                3: [ "Press de banca", "Aperturas polea", "Press de hombros máquina", "Extensión tríceps polea", "Plancha abdominal" ],
                4: [ "Remo con barra", "Jalón al pecho", "Face Pull", "Curl barra Z", "Abdominales banco" ],
                5: [ "Press militar con mancuernas", "Elevaciones laterales máquina", "Elevaciones frontales polea", "Pájaros", "Rotación de torso en máquina" ],
                6: [ "Press de pecho máquina", "Remo polea baja", "Pull-over en maquina", "Curl invertido", "Crunch en máquina" ]
            ]
        ),
        
        // MARK: - 2 días (Principiante) - Pierna Quad/Ham
        RoutineDefinition(
            id: UUID(),
            title: "Pierna 2 días (Quad/Ham)",
            subtitle: "Un día cuádriceps, otro femoral/glúteo",
            nivel: .principiante,
            diasPorSemana: 2,
            weeklyPlanNames: [
                3: [ "Prensa", "Extensión cuádriceps", "Sentadilla hack", "Elevación de talones de pie", "Crunch en máquina" ],
                6: [ "Zancadas mancuernas", "Curl femoral sentado", "Curl femoral tumbado", "Hip thrust", "Plancha abdominal" ]
            ]
        ),
        
        // MARK: - 3 días (Intermedio) - Brazos & Core
        RoutineDefinition(
            id: UUID(),
            title: "Brazos & Core 3 días",
            subtitle: "Bíceps/Tríceps con núcleo sólido",
            nivel: .intermedio,
            diasPorSemana: 3,
            weeklyPlanNames: [
                2: [ "Curl barra Z", "Curl bíceps mancuernas", "Curl concentrado", "Crunch en máquina", "Plancha abdominal" ],
                4: [ "Extensión tríceps polea", "Extensión tras nuca", "Press francés", "Abdominales banco", "Rotación de torso en máquina" ],
                6: [ "Curl de bíceps en polea baja", "Curl martillo", "Extensión tríceps banco", "Crunch polea", "Plancha abdominal" ]
            ]
        ),
        
        // MARK: - 4 días (Intermedio) - Push/Pull
        RoutineDefinition(
            id: UUID(),
            title: "Push/Pull 4 días",
            subtitle: "Empuje y Tirón con frecuencia 2",
            nivel: .intermedio,
            diasPorSemana: 4,
            weeklyPlanNames: [
                2: [ "Press de banca", "Press inclinado", "Aperturas polea", "Extensión tríceps polea", "Press francés", "Crunch en máquina" ],
                3: [ "Remo con barra", "Jalón al pecho", "Remo polea baja", "Face Pull", "Curl barra Z", "Plancha abdominal" ],
                5: [ "Press de pecho máquina", "Pec deck", "Press de hombros máquina", "Pájaros", "Extensión tras nuca", "Abdominales banco" ],
                6: [ "Dominadas", "Remo T máquina", "Remo mancuernas 1 mano", "Pull-over en maquina", "Curl martillo", "Rotación de torso en máquina" ]
            ]
        ),
        // MARK: - 1 día (Intermedio) - Full Body Express
        RoutineDefinition(
            id: UUID(),
            title: "Full Body 1 día (express)",
            subtitle: "Sesión completa en ~70′",
            nivel: .intermedio,
            diasPorSemana: 1,
            weeklyPlanNames: [
                2: [ // Lunes (se remapea a los días que elijas en la UI)
                    "Sentadilla barra",
                    "Press de banca",
                    "Remo con barra",
                    "Press militar con barra",
                    "Curl barra Z",
                    "Extensión tríceps polea",
                    "Crunch en máquina",
                    "Plancha abdominal"
                ]
            ]
        ),

        // MARK: - 1 día (Principiante) - Glúteo & Pierna
        RoutineDefinition(
            id: UUID(),
            title: "Glúteo & Pierna 1 día",
            subtitle: "Énfasis glúteo-femoral + core",
            nivel: .principiante,
            diasPorSemana: 1,
            weeklyPlanNames: [
                3: [ // Martes (se remapea a los días que elijas en la UI)
                    "Hip thrust",
                    "Prensa",
                    "Zancadas mancuernas",
                    "Curl femoral sentado",
                    "Extensión cuádriceps",
                    "Elevación de talones de pie",
                    "Crunch polea"
                ]
            ]
        )
    ]
}
