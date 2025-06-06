import SwiftUI

struct PlanesSuscripcionView: View {
    @State private var currentPlan: String = "Gratuito"
    @State private var selectedPlan: String = "Gratuito"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ENCABEZADO
                VStack(spacing: 8) {
                    Text("Tu plan actual")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(currentPlan)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)

                // PLAN GRATUITO
                SelectablePlanCard(
                    title: "Gratuito",
                    price: "0€ / mes",
                    features: [
                        ("chart.bar", "Estadísticas básicas"),
                        ("square.and.arrow.up", "Compartir entrenamientos"),
                        ("person.crop.circle", "Perfil público y seguidores"),
                        ("clock", "Comparativa de últimos 5 días")
                    ],
                    isSelected: selectedPlan == "Gratuito",
                    onTap: {
                        selectedPlan = "Gratuito"
                    },
                    backgroundColor: Color(.systemGray6)
                )

                // PLAN PRO
                SelectablePlanCard(
                    title: "Zymetrik Pro",
                    price: "4,99€ / mes",
                    features: [
                        ("infinity", "Comparativas ilimitadas"),
                        ("figure.run.circle", "Estadísticas avanzadas de running"),
                        ("star", "Acceso a rutinas premium"),
                        ("person.text.rectangle", "Diseño exclusivo de perfil")
                    ],
                    isSelected: selectedPlan == "Zymetrik Pro",
                    onTap: {
                        selectedPlan = "Zymetrik Pro"
                    },
                    backgroundColor: Color.yellow.opacity(0.8)
                )

                // PLAN PREMIUM
                SelectablePlanCard(
                    title: "Zymetrik Premium",
                    price: "9,99€ / mes",
                    features: [
                        ("video", "Videos exclusivos de entrenamiento"),
                        ("person.3", "Acceso a comunidad privada"),
                        ("lock.shield", "Contenido exclusivo y anticipado"),
                        ("bolt.shield", "Soporte prioritario VIP")
                    ],
                    isSelected: selectedPlan == "Zymetrik Premium",
                    onTap: {
                        selectedPlan = "Zymetrik Premium"
                    },
                    backgroundColor: Color.black
                )

                // BOTÓN
                Button(action: {
                    currentPlan = selectedPlan
                }) {
                    Text(currentPlan == selectedPlan ? "Plan activo" : "Suscribirme a \(selectedPlan)")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentPlan == selectedPlan ? Color.gray.opacity(0.3) : .black)
                        .foregroundColor(currentPlan == selectedPlan ? .gray : .white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .disabled(currentPlan == selectedPlan)
            }
            .padding(.horizontal)
            .navigationTitle("Planes y suscripción")
        }
    }
}
#Preview {
    PlanesSuscripcionView()
}
