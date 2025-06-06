import SwiftUI

struct SectionGroup: View {
    let title: String
    let items: [SettingRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    items[index]
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
    }
}
