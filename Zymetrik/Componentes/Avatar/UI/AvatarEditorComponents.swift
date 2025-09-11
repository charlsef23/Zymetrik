import SwiftUI

// MARK: - Filter Button
struct FilterButton: View {
    let filter: AvatarFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.blue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: filter.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(filter.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Adjustment Slider
struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    let step: Double
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        icon: String,
        step: Double = 0.1
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.icon = icon
        self.step = step
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        value = max(range.lowerBound, value - step)
                    }
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Slider(value: $value, in: range, step: step)
                    .tint(.blue)
                    .onChange(of: value) { oldValue, newValue in
                        if abs(newValue - oldValue) > step / 2 {
                            HapticManager.shared.selection()
                        }
                    }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        value = min(range.upperBound, value + step)
                    }
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reset Button
struct ResetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
                Text("Resetear")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
