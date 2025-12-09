import SwiftUI

struct TaskStorable: Identifiable {
    var id: UUID
    var title: String
    var isComplete: Bool = false
    
    init(title: String = "", isComplete: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isComplete = isComplete
    }
}
