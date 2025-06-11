import SwiftUI

struct EditarCampoNombreView: View {
    @Binding var nombre: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Tu nombre")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Nombre", text: $nombre)
                .textFieldStyle(.roundedBorder)

            Spacer()

        }
        .padding()
        .navigationTitle("Editar nombre")
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
