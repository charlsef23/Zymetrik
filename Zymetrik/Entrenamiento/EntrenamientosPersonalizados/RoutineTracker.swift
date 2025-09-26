// RoutineTracker.swift
import Foundation
import SwiftUI

/// Estado global de la rutina activa (nombre y rango de fechas).
/// Úsalo como .environmentObject(RoutineTracker.shared)
@MainActor
final class RoutineTracker: ObservableObject {
    static let shared = RoutineTracker()

    @Published var activePlanName: String? = nil
    @Published var activeRange: ClosedRange<Date>? = nil

    // Helpers opcionales
    var hasActiveRoutine: Bool { activePlanName != nil && activeRange != nil }

    func clear() {
        activePlanName = nil
        activeRange = nil
    }
}
