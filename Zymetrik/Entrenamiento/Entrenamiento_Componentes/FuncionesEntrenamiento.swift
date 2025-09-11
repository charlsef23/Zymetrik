import SwiftUI
import Foundation


extension Date {
    func isInLast(seconds: TimeInterval) -> Bool {
        return self >= Date().addingTimeInterval(-seconds)
    }
}
