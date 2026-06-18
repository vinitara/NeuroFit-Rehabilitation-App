import SwiftUI
import SwiftData

@main
struct Rehabilitation_AppApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingWrapper()
                }
            }
            .modelContainer(for: [UserProfile.self, ExerciseEntry.self, ExerciseCompletion.self, Badge.self])
        }
    }
}
// Wrapper to inject modelContext and persist the profile
struct OnboardingWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Query var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.first != nil {
                HomeView()
                    .onAppear {
                        if !hasCompletedOnboarding { hasCompletedOnboarding = true }
                    }
            } else {
                ProfileOnboardingView { profile in
                    let user = UserProfile(
                        name: profile.name,
                        age: profile.age,
                        gender: profile.gender,
                        heightCm: profile.heightCm,
                        weightKg: profile.weightKg
                    )
                    modelContext.insert(user)
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

