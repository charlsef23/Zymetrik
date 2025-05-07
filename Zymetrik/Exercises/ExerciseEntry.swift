//
//  ExerciseEntry.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//
import Foundation
import SwiftData

@Model
class ExerciseEntry {
    var name: String
    var sets: [ExerciseSet] = []

    init(name: String) {
        self.name = name
    }
}
