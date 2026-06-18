import SwiftData

@Model
final class UserProfile {
    var name: String
    var age: Int?
    var gender: String
    var heightCm: Double?
    var weightKg: Double?
    
    init(
        name: String,
        age: Int? = nil,
        gender: String,
        heightCm: Double? = nil,
        weightKg: Double? = nil
    ) {
        self.name = name
        self.age = age
        self.gender = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}
