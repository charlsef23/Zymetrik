import SwiftUI

struct CarruselEjerciciosView: View {
    let ejercicios: [EjercicioPostContenido]
    @Binding var ejercicioSeleccionado: EjercicioPostContenido?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ejercicios) { ejercicioItem in
                    Button {
                        withAnimation {
                            ejercicioSeleccionado = ejercicioItem
                        }
                    } label: {
                        VStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                            Text(ejercicioItem.nombre)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding()
                        .background(
                            ejercicioSeleccionado?.id == ejercicioItem.id ? Color(UIColor.systemGray5) : Color.white
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3))
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
