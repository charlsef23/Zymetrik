import SwiftUI

struct SelectablePlanCard: View {
    let title: String
    let price: String
    let features: [(String, String)]
    let isSelected: Bool
    let onTap: () -> Void
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)

                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(detailColor)
                }

                Spacer()

                if isSelected {
                    Text("Seleccionado")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(textColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Divider()
                .background(dividerColor)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.1) { icon, text in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(iconColor)
                            .frame(width: 20)
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(textColor)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(isSelected ? 0.2 : 0.05), radius: 6, x: 0, y: 3)
        .onTapGesture {
            onTap()
        }
    }

    // Estilos de texto según fondo
    private var textColor: Color {
        backgroundColor == .black || backgroundColor == Color("GoldColor") ? .white : .primary
    }

    private var detailColor: Color {
        backgroundColor == .black || backgroundColor == Color("GoldColor") ? .white.opacity(0.85) : .gray
    }

    private var dividerColor: Color {
        backgroundColor == .black || backgroundColor == Color("GoldColor") ? .white.opacity(0.3) : .gray.opacity(0.2)
    }

    private var iconColor: Color {
        backgroundColor == .black || backgroundColor == Color("GoldColor") ? .white : .blue
    }
}
