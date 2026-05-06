import SwiftUI

struct FocusScreenView: View {
    let task: TaskItem
    let onMarkComplete: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            Image(systemName: "target")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.accentColor.opacity(0.7))

            Text(task.title)
                .font(.system(size: 22, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 28)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button(action: onMarkComplete) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("Mark Complete")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.18))
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)

                Button(action: onExit) {
                    Text("Exit focus mode")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Esc")
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
}
