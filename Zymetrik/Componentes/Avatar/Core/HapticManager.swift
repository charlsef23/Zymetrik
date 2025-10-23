import UIKit

class HapticManager {
    static let shared = HapticManager()
    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // Conveniencia
    func success() { notification(.success) }
    func error() { notification(.error) }
    func warning() { notification(.warning) }
    func lightImpact() { impact(.light) }
    func mediumImpact() { impact(.medium) }
    func heavyImpact() { impact(.heavy) }
}
