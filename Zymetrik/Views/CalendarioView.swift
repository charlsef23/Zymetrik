import SwiftUI

struct CalendarioView: View {
    var body: some View {
        VStack {
            Text("Calendario de entrenamientos")
                .font(.title2)
                .fontWeight(.bold)
                .padding()

            Spacer()
            Text("Aquí irá la vista mensual del calendario")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}