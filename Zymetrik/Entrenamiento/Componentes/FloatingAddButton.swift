import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 24)
                .padding(.trailing, 24)
            }
        }
    }
}
