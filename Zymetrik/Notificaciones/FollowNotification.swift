import Foundation

public struct FollowNotificationPayload {
    public let followerID: String
    public let targetUserID: String
    public let didFollow: Bool
    public let targetFollowers: Int?
    public let meFollowing: Int?
}

public enum FollowNotification {
    public static let name = Notification.Name("followStateChanged")

    public static func post(
        followerID: String,
        targetUserID: String,
        didFollow: Bool,
        targetFollowers: Int? = nil,
        meFollowing: Int? = nil
    ) {
        NotificationCenter.default.post(
            name: Self.name,
            object: nil,
            userInfo: [
                "followerID": followerID,
                "targetUserID": targetUserID,
                "didFollow": didFollow,
                "targetFollowers": targetFollowers as Any,
                "meFollowing": meFollowing as Any
            ]
        )
    }
}
