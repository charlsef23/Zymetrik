import SwiftUI

extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(
        of value: T,
        perform action: @escaping (_ oldValue: T, _ newValue: T) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                action(oldValue, newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue, newValue) // iOS 16 no expone oldValue
            }
        }
    }
}
