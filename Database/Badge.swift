import Foundation
import SwiftData

@Model
final class Badge {
    var id: UUID
    var title: String
    var imageName: String
    var unlockedAt: Date?
    var isUnlocked: Bool
    
    init(id: UUID = UUID(), title: String, imageName: String, unlockedAt: Date? = nil, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.unlockedAt = unlockedAt
        self.isUnlocked = isUnlocked
    }
}

extension Badge {
    static let seedBadges: [(title: String, imageName: String)] = [
        ("First step\nto recovery", "badge1"),
        ("Rehab for\n3 days", "badge2"),
        ("Rehab for\n5 days", "badge3"),
        ("Rehab for\n7 days", "badge4"),
        ("Rehab for\n14 days", "badge5"),
        ("Rehab for\n30 days", "badge6")
    ]
    
    @discardableResult
    static func ensureSeeded(in context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<Badge>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return false }
        
        for item in seedBadges {
            let badge = Badge(title: item.title, imageName: item.imageName)
            context.insert(badge)
        }
        try context.save()
        return true
    }
}
