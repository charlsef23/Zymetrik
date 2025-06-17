import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://rmpgmdokzwfqdzqmrqmj.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtcGdtZG9rendmcWR6cW1ycW1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NzAyNzEsImV4cCI6MjA2NTA0NjI3MX0.5m7-BeL3D35qxjHE-lRnxe7AfaQhn2mheuP7-EqcEl8"
        )
    }
}
