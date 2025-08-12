// UI/AvatarAsyncImage.swift
import SwiftUI

struct AvatarAsyncImage: View {
    let url: URL?
    var size: CGFloat = 40
    
    var body: some View {
        AsyncImage(url: url) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.2))
                .overlay(Image(systemName: "person.fill").opacity(0.4))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
