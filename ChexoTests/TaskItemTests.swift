import Foundation
import SwiftData
import Testing
@testable import Chexo

@Suite("TaskItem model", .serialized)
@MainActor
final class TaskItemTests {
    let container: ModelContainer

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: TaskItem.self, configurations: config)
    }

    deinit {
        container.deleteAllData()
    }

    private func makeContext() -> ModelContext {
        ModelContext(container)
    }

    @Test("Init sets title and order, leaves isCompleted false")
    func initSetsProperties() {
        let task = TaskItem(title: "Buy milk", order: 0)
        #expect(task.title == "Buy milk")
        #expect(task.order == 0)
        #expect(task.isCompleted == false)
    }

    @Test("createdAt is set to approximately now on init")
    func createdAtDefaultsToNow() {
        let before = Date()
        let task = TaskItem(title: "Test", order: 0)
        let after = Date()
        #expect(task.createdAt >= before)
        #expect(task.createdAt <= after)
    }

    @Test("Inserting and fetching a task round-trips correctly")
    func insertAndFetchRoundTrip() throws {
        let context = makeContext()
        let original = TaskItem(title: "Write tests", order: 1)
        context.insert(original)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(fetched.count == 1)
        #expect(fetched[0].title == "Write tests")
        #expect(fetched[0].order == 1)
        #expect(fetched[0].isCompleted == false)
    }

    @Test("Multiple tasks persist independently")
    func multipleTasksPersist() throws {
        let context = makeContext()
        let tasks = (0..<5).map { TaskItem(title: "Task \($0)", order: $0) }
        for task in tasks { context.insert(task) }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(fetched.count == 5)
    }

    @Test("Toggling isCompleted persists")
    func togglingCompletion() throws {
        let context = makeContext()
        let task = TaskItem(title: "Toggle me", order: 0)
        context.insert(task)
        try context.save()

        task.isCompleted = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(fetched[0].isCompleted == true)
    }

    @Test("Updating title persists")
    func updatingTitle() throws {
        let context = makeContext()
        let task = TaskItem(title: "Old title", order: 0)
        context.insert(task)
        try context.save()

        task.title = "New title"
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(fetched[0].title == "New title")
    }

    @Test("Tasks sort by order")
    func tasksSortByOrder() throws {
        let context = makeContext()
        let tasks = [
            TaskItem(title: "Third", order: 2),
            TaskItem(title: "First", order: 0),
            TaskItem(title: "Second", order: 1),
        ]
        for task in tasks { context.insert(task) }
        try context.save()

        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.order)])
        let fetched = try context.fetch(descriptor)
        #expect(fetched.map(\.title) == ["First", "Second", "Third"])
    }

    @Test("Deleting a task removes it from the store")
    func deletingTask() throws {
        let context = makeContext()
        let task = TaskItem(title: "Delete me", order: 0)
        context.insert(task)
        try context.save()

        context.delete(task)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<TaskItem>())
        #expect(fetched.isEmpty)
    }
}
