import Charts
import SwiftUI

struct GraficaPesoView: View {
    let sesiones: [SesionEjercicio]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progreso")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            Chart {
                ForEach(sesiones) { sesion in
                    LineMark(
                        x: .value("Fecha", sesion.fecha),
                        y: .value("Peso", sesion.pesoTotal)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                    PointMark(
                        x: .value("Fecha", sesion.fecha),
                        y: .value("Peso", sesion.pesoTotal)
                    )
                    .symbol(Circle())
                    .symbolSize(20)
                    .foregroundStyle(Color.primary.opacity(0.9))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
                    AxisValueLabel(format: .dateTime.day(.defaultDigits), centered: true)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.1))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
    }
}
