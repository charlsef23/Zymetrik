import SwiftUI

struct PlanCardView: View {
    let title: String
    let price: String
    let features: [String]
    let gradient: LinearGradient
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if isCurrent {
                    Label("Activo", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(feature)
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(gradient)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}
