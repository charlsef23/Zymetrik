import SwiftUI

struct SeleccionResumen: View {
    let count: Int
    var onClearAll: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.circle.fill")
            Text("\(count) seleccionados hoy")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(role: .destructive, action: onClearAll) {
                Text("Quitar todos")
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
