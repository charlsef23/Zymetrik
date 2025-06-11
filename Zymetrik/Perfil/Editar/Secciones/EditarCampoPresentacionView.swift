import SwiftUI

struct EditarCampoPresentacionView: View {
    @Binding var presentacion: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Tu presentación")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $presentacion)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

            Spacer()
        }
        .padding()
        .navigationTitle("Editar presentación")
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
