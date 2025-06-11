import SwiftUI

struct EditarCampoUsernameView: View {
    @Binding var username: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Tu nombre de usuario")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Nombre de usuario", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Spacer()
        }
        .padding()
        .navigationTitle("Editar usuario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}
