import SwiftUI

struct CuentasBloqueadasView: View {
    let cuentasBloqueadas: [String] = [
        "usuario1", "usuario2", "usuario3"
    ] // Esto se reemplazará por datos reales más adelante

    var body: some View {
        VStack {
            if cuentasBloqueadas.isEmpty {
                Text("No has bloqueado a ningún usuario.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(cuentasBloqueadas, id: \.self) { usuario in
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.black)
                                )

                            Text("@\(usuario)")
                                .font(.body)

                            Spacer()

                            Button(role: .destructive) {
                                // Acción para desbloquear
                            } label: {
                                Text("Desbloquear")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Cuentas bloqueadas")
    }
}

#Preview {
    CuentasBloqueadasView()
}
