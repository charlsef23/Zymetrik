import Foundation

/// Params del RPC get_feed_posts con nulls explícitos
struct FeedParams: Encodable {
    let p_after_ts: String?     // ISO 8601 o nil
    let p_before_ts: String?    // ISO 8601 o nil
    let p_limit: Int
    let p_user: UUID

    enum CodingKeys: String, CodingKey { case p_after_ts, p_before_ts, p_limit, p_user }

    func encode(to encoder: Encoder) throws {
      var c = encoder.container(keyedBy: CodingKeys.self)
      if let v = p_after_ts  { try c.encode(v, forKey: .p_after_ts) }  else { try c.encodeNil(forKey: .p_after_ts) }
      if let v = p_before_ts { try c.encode(v, forKey: .p_before_ts) } else { try c.encodeNil(forKey: .p_before_ts) }
      try c.encode(p_limit, forKey: .p_limit)
      try c.encode(p_user,  forKey: .p_user)
    }
}
