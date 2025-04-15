//
//  FavoriteExercise.swift
//  FitFlow
//
//  Created by Carlos Esteve Fernández on 15/4/25.
//

import Foundation
import SwiftData

@Model
class FavoriteExercise {
    var name: String
    var category: String
    var createdAt: Date

    init(name: String, category: String) {
        self.name = name
        self.category = category
        self.createdAt = Date()
    }
}
