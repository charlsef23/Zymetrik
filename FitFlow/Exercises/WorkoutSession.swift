//
//  WorkoutSession.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//

import Foundation
import SwiftData

@Model
class WorkoutSession {
    var date: Date
    var title: String
    var isCompleted: Bool
    var exercises: [ExerciseEntry] = []

    init(date: Date, title: String, isCompleted: Bool = false) {
        self.date = date
        self.title = title
        self.isCompleted = isCompleted
    }
}
