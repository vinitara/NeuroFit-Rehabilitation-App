import Foundation
import SwiftData

@Model
final class ExerciseCompletion {
    var id: UUID
    var exerciseName: String
    var completedAt: Date
    var durationInMinutes: Int
    var animationName: String
    
    init(id: UUID = UUID(), exerciseName: String, completedAt: Date, durationInMinutes: Int = 0, animationName: String = "") {
        self.id = id
        self.exerciseName = exerciseName
        self.completedAt = completedAt
        self.durationInMinutes = durationInMinutes
        self.animationName = animationName
    }
}
