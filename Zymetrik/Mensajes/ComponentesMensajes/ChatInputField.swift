import SwiftUI
import Foundation

struct ChatInputField: View {
    @Binding var mensaje: String
    @FocusState var campoEnfocado: Bool
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Mensaje...", text: $mensaje)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .focused($campoEnfocado)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .rotationEffect(.degrees(45))
                    .padding(10)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}
