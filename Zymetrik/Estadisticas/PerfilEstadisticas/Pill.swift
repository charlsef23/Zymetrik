import SwiftUI

struct Pill: View {
    var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.caption2).opacity(0.8) }
            Text(text).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        )
    }
}
