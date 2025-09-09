import SwiftUI

struct LogroCardView: View {
    let logro: LogroConEstado

    var body: some View {
        let color = logro.desbloqueado ? (Color.fromHex(logro.color) ?? .accentColor) : .gray

        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(logro.desbloqueado ? color.opacity(0.2) : Color.gray.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: logro.icono_nombre)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)

                if !logro.desbloqueado {
                    Image(systemName: "lock.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.gray.opacity(0.9))
                        .padding(3)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: 16, y: -16)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(logro.titulo)
                    .font(.headline)
                    .foregroundColor(logro.desbloqueado ? .primary : .gray)

                Text(logro.descripcion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let fecha = logro.fecha, logro.desbloqueado {
                    Text("Desbloqueado el \(fecha.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}
