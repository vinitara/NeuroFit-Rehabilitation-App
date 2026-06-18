import Foundation
import SwiftData

@Model
final class ExerciseEntry {
    var id: UUID
    var date: Date
    var name: String
    var durationInMinutes: Int
    var isCompleted: Bool 
    
    init(id: UUID = UUID(), 
         date: Date, 
         name: String, 
         durationInMinutes: Int, 
         isCompleted: Bool = false) {
        self.id = id
        self.date = date
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.isCompleted = isCompleted
    }
} 
