import SwiftUI

struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.gray)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}