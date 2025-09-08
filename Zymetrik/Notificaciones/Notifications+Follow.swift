import Foundation

public extension Notification.Name {
    static let followStateChanged = Notification.Name("followStateChanged")
}

public struct FollowNotification {
    public static func post(targetUserID: String, didFollow: Bool) {
        NotificationCenter.default.post(
            name: .followStateChanged,
            object: nil,
            userInfo: ["targetUserID": targetUserID, "didFollow": didFollow]
        )
    }
}
