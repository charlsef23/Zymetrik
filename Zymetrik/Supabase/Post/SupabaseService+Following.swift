import Foundation

extension SupabaseService {

    struct FollowedUser: Decodable { let followed_id: UUID }

    /// Posts de autores seguidos por `userID`, ordenados por fecha DESC.
    func fetchFollowingPosts(userID: UUID, before: Date?, limit: Int = 20) async throws -> [Post] {
        // 1) Leer IDs de seguidos
        let followed: [FollowedUser] = try await SupabaseManager.shared.client
            .from("followers")
            .select("followed_id")
            .eq("follower_id", value: userID)
            .execute()
            .decodedList(to: FollowedUser.self)

        guard !followed.isEmpty else { return [] }

        // PostgREST `in` → necesitamos "in.(uuid1,uuid2,...)"
        let ids = followed.map { $0.followed_id.uuidString }
        let inList = "(\(ids.joined(separator: ",")))"

        // 2) Construir query aplicando filtros ANTES de order/limit
        var filtered = SupabaseManager.shared.client
            .from("posts")
            .select() // o .select("id,fecha,autor_id,avatar_url,username,contenido")
            .filter("autor_id", operator: "in", value: inList) // autor_id ∈ seguidos

        if let before {
            // Filtro por fecha anterior al cursor (aplicar aquí, antes de order())
            filtered = filtered.lt("fecha", value: before.ISO8601Format())
        }

        // Ahora ya podemos transformar: ordenar y limitar
        let res = try await filtered
            .order("fecha", ascending: false)
            .limit(limit)
            .execute()

        return try res.decodedList(to: Post.self)
    }
}
