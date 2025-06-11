import SwiftUI

struct ProfileEditRow<Destination: View>: View {
    let title: String
    let value: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                    .frame(minWidth: 120, alignment: .leading)

                Spacer()

                Text(value)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.leading, 4)
            }
            .frame(height: 44)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
