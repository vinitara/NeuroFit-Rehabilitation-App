import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Environment(\.modelContext) private var modelContext
  
    @Query(sort: \ExerciseCompletion.completedAt, order: .reverse) 
    private var allCompletions: [ExerciseCompletion]
    
    @State private var exercises: [RehabExercise] = [
        RehabExercise(name: "Wrist Place and Hold", duration: 2.0, region: "Hand & Wrist", animationName: "ex1", isBilateral: true),
        RehabExercise(name: "Side Arm Raise", duration: 1.5, region: "Arm", animationName: "ex2", isBilateral: true),
        RehabExercise(name: "Knee Extension", duration: 1.5, region: "Leg", animationName: "ex3", isBilateral: true),
        RehabExercise(name: "Trunk Rotation", duration: 2, region: "Core", animationName: "ex4", isBilateral: true),
        RehabExercise(name: "Wrist Bend Movement", duration: 1.5, region: "Hand & Wrist", animationName: "ex5", isBilateral: true),
        RehabExercise(name: "Bicep Curl", duration: 1.5, region: "Arm", animationName: "ex6", isBilateral: true),
        RehabExercise(name: "Hip Flexion with Hold", duration: 1.5, region: "Leg", animationName: "ex7", isBilateral: true),
        RehabExercise(name: "Seated Trunk Extension", duration: 1.5, region: "Core", animationName: "ex8", isBilateral: false)
    ]
    
    private func isCompletedToday(_ exercise: RehabExercise) -> Bool {
        let calendar = Calendar.current
        return allCompletions.contains { completion in
            completion.exerciseName == exercise.name && 
            calendar.isDateInToday(completion.completedAt)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 248/255, green: 251/255, blue: 248/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        headerSection
                            .padding(.top, 40)
                        
                        // "Today's Completed" summary list removed as requested
                        
                        ForEach(exercises) { exercise in
                            NavigationLink(destination: ContentView(exercise: exercise)) {
                                ExerciseCard(
                                    exercise: exercise,
                                    isCompletedToday: isCompletedToday(exercise)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Exercise")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Your Rehab Exercise Routine")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            
            Text("Welcome! Get started with your daily exercises")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    let exercise: RehabExercise
    let isCompletedToday: Bool
    
    private let purpleTheme = Color(red: 235/255, green: 225/255, blue: 255/255)
    
    private var regionSymbolName: String {
        switch exercise.region {
        case "Hand & Wrist": return "hand.raised"
        case "Arm": return "dumbbell"
        case "Leg": return "figure.walk"
        case "Core": return "figure.stand"
        default: return "figure.strengthtraining.traditional"
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: regionSymbolName)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(exercise.name)
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                    
                    // MARK: - Larger Purple Completed Sign
                    if isCompletedToday {
                        Text("Completed")
                            .font(.system(size: 14, weight: .bold, design: .rounded)) // Increased from 12 to 14
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(purpleTheme)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.primary)
                
                Text("Duration: \(String(format: "%.1f", exercise.duration)) min • Region: \(exercise.region)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // MARK: - Redo Button / Start Button
            if isCompletedToday {
                // REDO Button Style
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                    Text("Redo")
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(.black)
                .background(Color.black.opacity(0.05)) // Monochromatic style
                .clipShape(Capsule())
            } else {
                // Original Start Button Style
                Text("Start")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 248/255, green: 251/255, blue: 248/255))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.03), lineWidth: 0.7)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 24)
        .frame(width: 650, height: 110)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                Color(red: 236/255, green: 244/255, blue: 239/255)
                    .opacity(0.7)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        ExerciseView()
    }
}

