import SwiftUI
import SwiftData

struct TaskRow: View {
    @Bindable var task: TaskItem

    let isFocused: Bool
    let anyTaskFocused: Bool
    let onSetFocus: () -> Void
    let onClearFocus: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var isExpanded = false
    @State private var checkScale: CGFloat = 1.0
    @State private var didCopy = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0
    @FocusState private var fieldFocused: Bool

    private let collapsedLineLimit = 2

    private var isTruncated: Bool { fullHeight > collapsedHeight + 0.5 }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            checkbox
            textContent
            Spacer(minLength: 0)
            actionButtons
        }
        .padding(.vertical, isFocused ? 8 : 6)
        .padding(.horizontal, isFocused ? 10 : 8)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(alignment: .leading) {
            if isFocused && !task.isCompleted {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .padding(.vertical, 4)
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }
        }
        .opacity(opacityForFocus)
        .offset(y: task.isCompleted ? 1 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: anyTaskFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: task.isCompleted)
        .onHover { isHovered = $0 }
        .contextMenu { focusContextMenu }
    }

    private var opacityForFocus: Double {
        if anyTaskFocused && !isFocused { return 0.4 }
        return 1.0
    }

    @ViewBuilder
    private var focusContextMenu: some View {
        if !task.isCompleted {
            if isFocused {
                Button("Clear Focus") { onClearFocus() }
            } else {
                Button("Set as Focus") { onSetFocus() }
            }
        }
        Button("Edit") { beginEdit() }
        Button("Copy Task", action: copyTask)
        Divider()
        Button("Delete", role: .destructive, action: { onDelete() })
    }

    // MARK: - Checkbox

    private var checkbox: some View {
        Button(action: toggleComplete) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundStyle(checkBoxColor)
                .scaleEffect(checkScale)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: task.isCompleted)
        .padding(.top, 1)
    }

    private var checkBoxColor: Color {
        if task.isCompleted { return .green }
        if isFocused { return Color.accentColor.opacity(0.7) }
        return .secondary
    }

    // MARK: - Text

    private var titleFont: Font {
        .system(size: 13, weight: isFocused ? .medium : .regular)
    }

    private var textColor: Color {
        if task.isCompleted { return .secondary }
        return isFocused ? .primary : .primary.opacity(0.85)
    }

    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isEditing {
                TextField("Task", text: $task.title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(titleFont)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: fieldFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
                    .onAppear {
                        Task { @MainActor in fieldFocused = true }
                    }
            } else {
                Text(task.title)
                    .font(titleFont)
                    .foregroundStyle(textColor)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(isExpanded ? nil : collapsedLineLimit)
                    .multilineTextAlignment(.leading)
                    .background(truncationMeasurer)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { beginEdit() }
            }

            if !isEditing && (isExpanded || isTruncated) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.vertical, 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var truncationMeasurer: some View {
        ZStack(alignment: .topLeading) {
            Text(task.title)
                .font(titleFont)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { fullHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, h in fullHeight = h }
                            .onChange(of: task.title) { _, _ in fullHeight = proxy.size.height }
                    }
                )

            Text(task.title)
                .font(titleFont)
                .multilineTextAlignment(.leading)
                .lineLimit(collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { collapsedHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, h in collapsedHeight = h }
                            .onChange(of: task.title) { _, _ in collapsedHeight = proxy.size.height }
                    }
                )
        }
        .hidden()
        .allowsHitTesting(false)
    }

    private func beginEdit() {
        guard !task.isCompleted else { return }
        isExpanded = true
        isEditing = true
    }

    private func commitEdit() {
        let trimmed = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != task.title {
            task.title = trimmed
        }
        isEditing = false
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        if isHovered || didCopy {
            HStack(spacing: 8) {
                if !task.isCompleted {
                    Button(action: toggleFocus) {
                        Image(systemName: isFocused ? "target" : "scope")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isFocused ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isFocused ? "Clear focus" : "Set as focus")
                    .transition(.opacity.animation(.easeOut(duration: 0.15)))
                }

                Button(action: copyTask) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(didCopy ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy task title")
                .transition(.opacity.animation(.easeOut(duration: 0.15)))

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete task")
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isFocused && !task.isCompleted {
            Color.accentColor.opacity(0.06)
        } else if isHovered && !task.isCompleted {
            Color.primary.opacity(0.04)
        } else if task.isCompleted {
            Color.primary.opacity(0.02)
        }
    }

    private func toggleFocus() {
        if isFocused { onClearFocus() } else { onSetFocus() }
    }

    private func copyTask() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(task.title, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) {
            didCopy = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.3)) {
                didCopy = false
            }
        }
    }

    private func toggleComplete() {
        withAnimation(.spring(response: 0.12, dampingFraction: 0.8)) {
            checkScale = 0.85
        }
        Task {
            try? await Task.sleep(for: .seconds(0.06))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkScale = 1.1
                task.isCompleted.toggle()
            }
            if isFocused && task.isCompleted {
                onClearFocus()
            }
            try? await Task.sleep(for: .seconds(0.19))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                checkScale = 1.0
            }
        }
    }
}
