import Foundation

enum AppPhase: Equatable {
    case loading(progress: Double, message: String?)
    case ready
    case error(message: String)
}
