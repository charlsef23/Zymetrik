import SwiftUI

struct CommentSkeleton: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(Color(.secondarySystemBackground)).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 120, height: 10)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 36)
            }
        }
        .redacted(reason: .placeholder)
    }
}
