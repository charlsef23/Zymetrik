import Foundation
import SwiftData

@Model
class FavoriteWorkoutTitle {
    var title: String
    var createdAt: Date

    init(title: String) {
        self.title = title
        self.createdAt = Date()
    }
}
