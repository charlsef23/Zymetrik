import SwiftUI

extension AvatarAsyncImage {
    // Presets para diferentes contextos
    
    static func profile(url: String?) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.large,
            showBorder: true,
            borderColor: AvatarConstants.Colors.borderDefault,
            borderWidth: 3
        )
    }
    
    static func list(url: String?) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.medium,
            showBorder: true,
            borderColor: AvatarConstants.Colors.borderDefault,
            borderWidth: 2
        )
    }
    
    static func comment(url: String?) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.small,
            showBorder: false
        )
    }
    
    static func story(url: String?, hasNewStory: Bool = false) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.large,
            showBorder: true,
            borderColor: hasNewStory ? .orange : AvatarConstants.Colors.borderDefault,
            borderWidth: hasNewStory ? 3 : 2
        )
    }
    
    static func message(url: String?) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.medium,
            showBorder: false
        )
    }
    
    static func notification(url: String?) -> AvatarAsyncImage {
        AvatarAsyncImage(
            url: URL(string: url ?? ""),
            size: AvatarConstants.extraSmall,
            showBorder: false
        )
    }
}
