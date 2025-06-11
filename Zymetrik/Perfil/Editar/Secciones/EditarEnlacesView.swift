import SwiftUI

struct EditarCampoEnlacesView: View {
    @Binding var enlaces: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Tus enlaces (redes, web, etc.)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Añadir enlaces", text: $enlaces)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Spacer()
        }
        .padding()
        .navigationTitle("Editar enlaces")
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
