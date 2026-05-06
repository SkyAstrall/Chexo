import Foundation
import SwiftData

/// A user task stored in SwiftData.
///
/// Each task has a title, completion state, display order, and creation timestamp.
/// Tasks are queried sorted by ``order`` and grouped into active and completed sections.
@Model
final class TaskItem {
    /// The user-entered title of the task.
    var title: String

    /// Whether the task has been marked complete.
    var isCompleted = false

    /// The display position among all tasks, used for drag-to-reorder.
    var order: Int

    /// The timestamp when the task was created.
    var createdAt = Date()

    /// Creates a new task with the given title and display position.
    /// - Parameters:
    ///   - title: The task description.
    ///   - order: The position in the task list.
    init(title: String, order: Int) {
        self.title = title
        self.order = order
    }
}
