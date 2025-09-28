import SwiftUI

public struct RoutinePillButton: View {
    public let title: String
    public var onTap: () -> Void

    public init(title: String, onTap: @escaping () -> Void) {
        self.title = title
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                Text(title)
                    .font(.caption2).bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.15)))
            .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rutina activa: \(title)")
    }
}
