import SwiftUI
import Foundation

struct ChatHeaderView: View {
    let receptorUsername: String
    let avatarURL: String?

    var body: some View {
        HStack(spacing: 12) {
            let url = URL(string: avatarURL ?? "")
            AvatarAsyncImage(url: url, size: 44)

            VStack(alignment: .leading) {
                Text(receptorUsername)
                    .font(.headline)
                Text("En línea")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
