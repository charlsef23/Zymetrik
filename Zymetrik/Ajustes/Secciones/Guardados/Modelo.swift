import SwiftUI
import Foundation

struct CarpetaGuardado: Identifiable, Hashable, Equatable {
    let id = UUID()
    var nombre: String
    var posts: [EntrenamientoPost]
}

