import SwiftUI
import Combine
import CoreData

class TaskViewModel: ObservableObject {
    
    @Published var tasks: [TaskStorable] = []
    
    private var dataManager = DataManager.shared
    
    init() {
        self.tasks = dataManager.tasksArray
        observeDataManager()
    }
    
    private func observeDataManager() {
        dataManager.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDict in
                self?.tasks = Array(newDict.values)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    func addTask(_ title: String) {
        let newTask = TaskStorable(title: title)
        dataManager.updateAndSave(todo: newTask)
    }
    func toggleCompletion(for task: TaskStorable) {
        var updated = task
        updated.isComplete.toggle()
        dataManager.updateAndSave(todo: updated)
    }
    func deleteTask(_ task: TaskStorable) {
        dataManager.delete(todo: task)
    }
}
