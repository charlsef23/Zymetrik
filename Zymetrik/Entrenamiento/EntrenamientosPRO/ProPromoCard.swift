import SwiftUI

struct ProPromoCard: View {
    var priceText: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Planes de Entrenamiento Personalizados")
                        .font(.headline).bold()
                    Text("Desbloquea rutinas por nivel y objetivo · \(priceText)")
                        .font(.subheadline)
                        .opacity(0.9)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline).bold()
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.purple, .pink, .orange],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .accessibilityLabel("Abrir plantillas PRO")
        }
        .buttonStyle(.plain)
    }
}
