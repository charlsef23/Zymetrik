import SwiftUI

struct BotonFlotanteView: View {
    @Binding var mostrarAcciones: Bool
    var onAddEntrenamiento: () -> Void
    var onAddEjercicio: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if mostrarAcciones {
                VStack(spacing: 16) {
                    Button(action: onAddEntrenamiento) {
                        Label("Nuevo entrenamiento", systemImage: "figure.strengthtraining.traditional")
                            .padding(12)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Button(action: onAddEjercicio) {
                        Label("Nuevo ejercicio", systemImage: "bolt.fill")
                            .padding(12)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .transition(.scale)
                .padding(.trailing, 16)
                .padding(.bottom, 90)
            }

            Button {
                // Nada, usamos solo long press
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black))
                    .shadow(radius: 4)
            }
            .padding()
            .simultaneousGesture(
                LongPressGesture().onEnded { _ in
                    withAnimation(.spring()) {
                        mostrarAcciones.toggle()
                    }
                }
            )
        }
    }
}

#Preview {
    BotonFlotanteView(mostrarAcciones: .constant(true), onAddEntrenamiento: {}, onAddEjercicio: {})
}