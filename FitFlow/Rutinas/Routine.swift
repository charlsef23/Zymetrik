//
//  Routine.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//

import Foundation
import SwiftData

@Model
class Routine {
    var name: String
    var exercises: [RoutineExercise] = []

    init(name: String) {
        self.name = name
    }
}

@Model
class RoutineExercise {
    var name: String
    var sets: [ExerciseSet] = []

    init(name: String) {
        self.name = name
    }
}
