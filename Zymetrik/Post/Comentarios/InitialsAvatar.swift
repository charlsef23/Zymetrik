import SwiftUI

struct InitialsAvatar: View {
    let name: String
    let size: CGFloat

    private var initials: String {
        let comps = name.split(separator: " ")
        let first = comps.first?.first.map(String.init) ?? ""
        let second = comps.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(Text(initials).font(.caption.bold()))
    }
}
