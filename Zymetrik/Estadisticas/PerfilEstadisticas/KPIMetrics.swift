import Foundation

struct KPIMetrics {
    let bestRM: Double
    let totalVolumen: Double
    let ultimaFecha: Date?

    init(sesiones: [SesionEjercicio]) {
        self.bestRM = sesiones.map { $0.pesoTotal }.max() ?? 0
        self.totalVolumen = sesiones.map { $0.pesoTotal }.reduce(0, +)
        self.ultimaFecha = sesiones.sorted(by: { $0.fecha > $1.fecha }).first?.fecha
    }

    var bestRMString: String { number(bestRM) + " kg" }
    var totalVolumenString: String { number(totalVolumen) + " kg" }
    var ultimaFechaString: String {
        guard let d = ultimaFecha else { return "—" }
        let df = DateFormatter(); df.dateStyle = .short
        return df.string(from: d)
    }

    private func number(_ v: Double) -> String {
        let f = NumberFormatter(); f.maximumFractionDigits = 1; f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}
