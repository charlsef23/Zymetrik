import SwiftUI

struct SimplePlanCard: View {
    let title: String
    let price: String
    let features: [(String, String)]
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                if isActive {
                    Text("Activo")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.1) { icon, text in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text(text)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
