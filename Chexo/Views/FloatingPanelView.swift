import SwiftUI
import SwiftData

/// The main view rendered inside the floating panel.
///
/// Displays a task list with a progress bar, text input for adding tasks,
/// and an optional focus mode that isolates a single task. Manages focus state
/// persistence so the focused task survives app restarts.
struct FloatingPanelView: View {
    let onCollapse: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.order) private var tasks: [TaskItem]

    @State private var newTitle = ""
    @State private var panelHovered = false
    @State private var focusedTaskID: PersistentIdentifier? = nil
    @State private var focusScreen = false
    @FocusState private var inputFocused: Bool

    @AppStorage("focusedTaskIDData") private var focusedTaskIDData: Data = Data()
    @AppStorage("showCompleted") private var showCompleted: Bool = false
    @AppStorage("focusScreenEnabled") private var focusScreenEnabled: Bool = false

    /// Incomplete tasks, filtered from all tasks.
    private var activeTasks: [TaskItem] { tasks.filter { !$0.isCompleted } }

    /// Completed tasks, filtered from all tasks.
    private var completedTasks: [TaskItem] { tasks.filter { $0.isCompleted } }

    /// The number of completed tasks.
    private var doneCount: Int { completedTasks.count }

    /// The fraction of tasks completed, from 0 to 1.
    private var completionFraction: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(doneCount) / Double(tasks.count)
    }

    /// The currently focused task, if it exists and is not completed.
    private var focusedTask: TaskItem? {
        guard let id = focusedTaskID else { return nil }
        return tasks.first { $0.persistentModelID == id && !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressLine
            if focusScreen, let focused = focusedTask {
                focusScreenBody(task: focused)
            } else {
                taskList
                inputBar
            }
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(
            color: .black.opacity(panelHovered ? 0.18 : 0.10),
            radius: panelHovered ? 16 : 8,
            y: panelHovered ? 5 : 2
        )
        .animation(.easeOut(duration: 0.25), value: panelHovered)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: focusScreen)
        .onHover { panelHovered = $0 }
        .frame(minWidth: 280, minHeight: 300)
        .background(keyboardShortcutCatcher)
        .onAppear { hydratePersistedState() }
        .onChange(of: focusedTaskID) { _, newID in
            persistFocus(newID)
            if newID == nil { focusScreen = false }
        }
        .onChange(of: focusScreen) { _, newValue in
            focusScreenEnabled = newValue
        }
        .onChange(of: tasks) { _, newTasks in
            if let id = focusedTaskID,
               !newTasks.contains(where: { $0.persistentModelID == id && !$0.isCompleted }) {
                focusedTaskID = nil
            }
        }
    }

    // MARK: - Header

    /// The panel header showing the title, task count, and control buttons.
    private var header: some View {
        HStack(spacing: 8) {
            Text("Tasks")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if focusedTaskID != nil && !focusScreen {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        focusScreen = true
                    }
                } label: {
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .help("Enter focus mode")
                .transition(.scale.combined(with: .opacity))
            }

            if !tasks.isEmpty {
                Text("\(doneCount)/\(tasks.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText())
            }

            Button(action: onCollapse) {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .help("Collapse")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Color.primary.opacity(0.05), Color.clear],
                startPoint: .bottom,
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .frame(height: 6)
            .offset(y: 6)
        }
    }

    /// A thin progress bar showing the fraction of tasks completed.
    private var progressLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.primary.opacity(0.06)
                Color.accentColor.opacity(0.5)
                    .frame(width: geo.size.width * completionFraction)
            }
        }
        .frame(height: 3)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: completionFraction)
    }

    // MARK: - Task list

    /// The task list, or an empty-state placeholder when there are no tasks.
    @ViewBuilder
    private var taskList: some View {
        if tasks.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "checklist")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.quaternary)
                VStack(spacing: 3) {
                    Text("No tasks yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Text("Press \u{2318}N to start typing")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }
            Spacer()
        } else {
            List {
                activeSection
                if !completedTasks.isEmpty {
                    completedSection
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.primary.opacity(0.02))
        }
    }

    /// The section displaying active (incomplete) tasks.
    @ViewBuilder
    private var activeSection: some View {
        if activeTasks.isEmpty && completedTasks.isEmpty {
            EmptyView()
        } else {
            Section {
                ForEach(activeTasks) { task in
                    TaskRow(
                        task: task,
                        isFocused: task.persistentModelID == focusedTaskID,
                        anyTaskFocused: focusedTaskID != nil,
                        onSetFocus: { setFocus(task) },
                        onClearFocus: clearFocus,
                        onDelete: { delete(task) }
                    )
                }
                .onMove(perform: move)
            }
        }
    }

    /// The collapsible section displaying completed tasks with a count.
    @ViewBuilder
    private var completedSection: some View {
        Section {
            if showCompleted {
                ForEach(completedTasks) { task in
                    TaskRow(
                        task: task,
                        isFocused: false,
                        anyTaskFocused: focusedTaskID != nil,
                        onSetFocus: { setFocus(task) },
                        onClearFocus: clearFocus,
                        onDelete: { delete(task) }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showCompleted.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .rotationEffect(.degrees(showCompleted ? 90 : 0))
                    Text("Completed")
                    Text("(\(doneCount))")
                        .foregroundStyle(.quaternary)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Focus screen

    /// The focus mode view that isolates a single task with a completion button.
    /// - Parameter task: The task to focus on.
    private func focusScreenBody(task: TaskItem) -> some View {
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
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        task.isCompleted = true
                        clearFocus()
                    }
                } label: {
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

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        focusScreen = false
                    }
                } label: {
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

    // MARK: - Input

    /// The text field and add button for creating new tasks.
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("New task", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($inputFocused)
                .onSubmit(add)

            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .foregroundStyle(newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .quaternary : .secondary)
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        )
    }

    /// The translucent material background for the panel.
    @ViewBuilder
    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
    }

    // MARK: - Keyboard shortcuts

    /// Hidden buttons that capture keyboard shortcuts for task creation and escape.
    private var keyboardShortcutCatcher: some View {
        ZStack {
            Button("New task", action: focusInput)
                .keyboardShortcut("n", modifiers: .command)
            Button("Escape", action: handleEscape)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    /// Activates the text field for entering a new task.
    private func focusInput() {
        if focusScreen { return }
        inputFocused = true
    }

    /// Handles the Escape key depending on the current state.
    private func handleEscape() {
        if focusScreen {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                focusScreen = false
            }
        } else if focusedTaskID != nil {
            clearFocus()
        } else {
            onCollapse()
        }
    }

    // MARK: - Persistence

    /// Restores the focused task and focus screen state from persisted data on appear.
    private func hydratePersistedState() {
        guard !focusedTaskIDData.isEmpty else { return }
        if let decoded = try? JSONDecoder().decode(PersistentIdentifier.self, from: focusedTaskIDData),
           tasks.contains(where: { $0.persistentModelID == decoded && !$0.isCompleted }) {
            focusedTaskID = decoded
            if focusScreenEnabled {
                focusScreen = true
            }
        } else {
            focusedTaskIDData = Data()
            focusScreenEnabled = false
        }
    }

    /// Encodes and persists the focused task identifier, or clears it if nil.
    private func persistFocus(_ id: PersistentIdentifier?) {
        if let id, let data = try? JSONEncoder().encode(id) {
            focusedTaskIDData = data
        } else {
            focusedTaskIDData = Data()
        }
    }

    // MARK: - Mutations

    /// Adds a new task with the current input text.
    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            context.insert(TaskItem(title: trimmed, order: tasks.count))
        }
        newTitle = ""
    }

    /// Deletes the given task, clearing focus if it was focused.
    /// - Parameter task: The task to remove.
    private func delete(_ task: TaskItem) {
        if task.persistentModelID == focusedTaskID {
            focusedTaskID = nil
        }
        withAnimation(.easeOut(duration: 0.18)) {
            context.delete(task)
        }
    }

    /// Sets the given task as the focused task.
    /// - Parameter task: The task to focus on.
    private func setFocus(_ task: TaskItem) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) {
            focusedTaskID = task.persistentModelID
        }
    }

    /// Clears the current focus state.
    private func clearFocus() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            focusedTaskID = nil
        }
    }

    /// Reorders active tasks after a drag-and-drop move, preserving completed tasks' order below.
    /// - Parameters:
    ///   - source: The index set of the tasks being moved.
    ///   - destination: The destination index in the active tasks array.
    private func move(from source: IndexSet, to destination: Int) {
        var reorderedActive = activeTasks
        reorderedActive.move(fromOffsets: source, toOffset: destination)
        for (i, t) in reorderedActive.enumerated() {
            t.order = i
        }
        let activeCount = reorderedActive.count
        for (i, t) in completedTasks.enumerated() {
            t.order = activeCount + i
        }
    }
}
