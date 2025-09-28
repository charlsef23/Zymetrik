// TrainingEnums.swift
import Foundation

public enum NivelEntrenamiento: String, CaseIterable, Identifiable {
    case principiante = "Principiante"
    case intermedio   = "Intermedio"
    case avanzado     = "Avanzado"
    public var id: String { rawValue }
}

public enum FocoPlan: String, CaseIterable, Identifiable {
    case fuerza = "Fuerza"
    case cardio = "Cardio"
    case hibrido = "Híbrido"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .fuerza:  return "dumbbell"
        case .cardio:  return "figure.run"
        case .hibrido: return "bolt.heart"
        }
    }
}
