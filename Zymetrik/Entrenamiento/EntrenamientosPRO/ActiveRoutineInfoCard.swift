import SwiftUI

struct ActiveRoutineInfoCard: View {
    var name: String
    var range: ClosedRange<Date>?
    var onManage: () -> Void

    private var rangoTexto: String {
        guard let r = range else { return "Plan activo" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_ES")
        df.dateStyle = .medium
        return "\(df.string(from: r.lowerBound)) – \(df.string(from: r.upperBound))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline).bold().lineLimit(1)
                Text(rangoTexto).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button("Gestionar") { onManage() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}
