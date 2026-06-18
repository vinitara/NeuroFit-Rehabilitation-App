import Foundation

enum ExerciseType {
    case wristHold
    case sideArmRaise
    case kneeExtension
    case trunkRotation
    case wristBend
    case bicepCurl
    case hipFlexion
    case seatedTrunkExtension
}

struct RehabExercise: Identifiable {
    let id = UUID()
    let name: String
    let duration: Double
    let region: String
    let animationName: String
    let isCompleted: Bool = false
    let isBilateral: Bool
}
