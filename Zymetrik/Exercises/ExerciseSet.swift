//
//  ExerciseSet.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//
import Foundation
import SwiftData

@Model
class ExerciseSet {
    var reps: Int
    var weight: Double

    init(reps: Int, weight: Double) {
        self.reps = reps
        self.weight = weight
    }
}
