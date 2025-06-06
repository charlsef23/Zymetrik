import SwiftUI

struct SettingRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var destination: AnyView? = nil

    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.primary)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            if let value = value {
                Text(value)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
    }
}
