import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var isCompleted = false
    var order: Int
    var createdAt = Date()

    init(title: String, order: Int) {
        self.title = title
        self.order = order
    }
}
