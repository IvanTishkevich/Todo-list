import Foundation
import CoreData
import OrderedCollections


enum DataManagerType {
    case normal
    case preview
    case testing
}

class DataManager: NSObject, ObservableObject {
    
    static let shared = DataManager(type: .normal)
    static let preview = DataManager(type: .preview)
    static let testing = DataManager(type: .testing)
    
    @Published var tasks: OrderedDictionary<UUID, TaskStorable> = [:]
    
    var tasksArray: [TaskStorable] {
        Array(tasks.values)
    }
    
    fileprivate var managedObjectContext: NSManagedObjectContext
    private let tasksFRC: NSFetchedResultsController<TaskStorableMO>
    
    private init(type: DataManagerType) {
        switch type {
        case .normal:
            let persistentStore = PersistentStore()
            self.managedObjectContext = persistentStore.context
        case .preview:
            let persistentStore = PersistentStore(inMemory: true)
            self.managedObjectContext = persistentStore.context
            for i in 0..<10 {
                let newTodo = TaskStorableMO(context: managedObjectContext)
                newTodo.title = "Todo \(i)"
                newTodo.isComplete = false
                newTodo.id = UUID()
            }
            try? self.managedObjectContext.save()
        case .testing:
            let persistentStore = PersistentStore(inMemory: true)
            self.managedObjectContext = persistentStore.context
        }
        
        let tasksFR: NSFetchRequest<TaskStorableMO> = TaskStorableMO.fetchRequest()
        tasksFR.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false)]
        tasksFRC = NSFetchedResultsController(fetchRequest: tasksFR,
                                              managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        
        super.init()
        
        tasksFRC.delegate = self
        try? tasksFRC.performFetch()
        if let newTasks = tasksFRC.fetchedObjects {
            self.tasks = OrderedDictionary(uniqueKeysWithValues: newTasks.map({ ($0.id!, TaskStorable(taskStorableMO: $0)) }))
        }
    }
    
    func saveData() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                NSLog("Unresolved error saving context: \(error), \(error.userInfo)")
            }
        }
    }
}

extension DataManager: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let newTasks = controller.fetchedObjects as? [TaskStorableMO] {
            self.tasks = OrderedDictionary(uniqueKeysWithValues: newTasks.map({ ($0.id!, TaskStorable(taskStorableMO: $0)) }))
        }
    }
    
    
    private func fetchFirst<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate?) -> Result<T?, Error> {
        let request = objectType.fetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1
        do {
            let result = try managedObjectContext.fetch(request) as? [T]
            return .success(result?.first)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchTodos(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) {
        if let predicate = predicate {
            tasksFRC.fetchRequest.predicate = predicate
        }
        if let sortDescriptors = sortDescriptors {
            tasksFRC.fetchRequest.sortDescriptors = sortDescriptors
        }
        try? tasksFRC.performFetch()
        if let newTasks = tasksFRC.fetchedObjects {
            self.tasks = OrderedDictionary(uniqueKeysWithValues: newTasks.map({ ($0.id!, TaskStorable(taskStorableMO: $0)) }))
        }
    }
    
    func resetFetch() {
        tasksFRC.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        tasksFRC.fetchRequest.predicate = nil
        try? tasksFRC.performFetch()
        if let newTasks = tasksFRC.fetchedObjects {
            self.tasks = OrderedDictionary(uniqueKeysWithValues: newTasks.map({ ($0.id!, TaskStorable(taskStorableMO: $0)) }))
        }
    }
    
    
}

extension TaskStorable {
    
    fileprivate init(taskStorableMO: TaskStorableMO) {
        self.id = taskStorableMO.id ?? UUID()
        self.title = taskStorableMO.title ?? ""
        self.isComplete = taskStorableMO.isComplete
    }
}



extension DataManager {
    
    func updateAndSave(todo: TaskStorable) {
        let predicate = NSPredicate(format: "id = %@", todo.id as CVarArg)
        let result = fetchFirst(TaskStorableMO.self, predicate: predicate)
        switch result {
        case .success(let managedObject):
            if let todoMo = managedObject {
                update(todoMO: todoMo, from: todo)
            } else {
                todoMO(from: todo)
            }
        case .failure(_):
            print("Couldn't fetch TodoMO to save")
        }
        
        saveData()
    }
    
    func delete(todo: TaskStorable) {
        let predicate = NSPredicate(format: "id = %@", todo.id as CVarArg)
        let result = fetchFirst(TaskStorableMO.self, predicate: predicate)
        switch result {
        case .success(let managedObject):
            if let todoMo = managedObject {
                managedObjectContext.delete(todoMo)
            }
        case .failure(_):
            print("Couldn't fetch TodoMO to save")
        }
        saveData()
    }
    
    func getTodo(with id: UUID) -> TaskStorable? {
        return tasks[id]
    }
    
    private func todoMO(from todo: TaskStorable) {
        let todoMO = TaskStorableMO(context: managedObjectContext)
        todoMO.id = todo.id
        update(todoMO: todoMO, from: todo)
    }
    
    private func update(todoMO: TaskStorableMO, from todo: TaskStorable) {
        todoMO.title = todo.title
        todoMO.isComplete = todo.isComplete
    }
    
    private func getTodoMO(from todo: TaskStorable?) -> TaskStorableMO? {
        guard let todo = todo else { return nil }
        let predicate = NSPredicate(format: "id = %@", todo.id as CVarArg)
        let result = fetchFirst(TaskStorableMO.self, predicate: predicate)
        switch result {
        case .success(let managedObject):
            if let todoMO = managedObject {
                return todoMO
            } else {
                return nil
            }
        case .failure(_):
            return nil
        }
    }
}
