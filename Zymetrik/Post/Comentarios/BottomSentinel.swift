import SwiftUI

struct BottomSentinel: View {
    let onAppear: () -> Void
    var body: some View {
        Color.clear.onAppear(perform: onAppear)
    }
}
