import SwiftUI
import SwiftData
import Combine

// MARK: - ViewModel
final class HomeViewModel: ObservableObject {
    @Published var hasActiveChallenge: Bool = true
    @AppStorage("profile.name") var userName: String = "Jane"
    let dailyTarget: Int = 8
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var context
    
    // FETCH: Get all completions
    @Query(sort: [SortDescriptor(\ExerciseCompletion.completedAt, order: .reverse)]) 
    private var allCompletions: [ExerciseCompletion]
    
    // LOGIC: Progress Calculations
    private var completedTodayCount: Int {
        let calendar = Calendar.current
        
        // 1. Get all completions from today
        let todayCompletions = allCompletions.filter { 
            calendar.isDateInToday($0.completedAt) 
        }
        
        // 2. Extract unique exercise names
        // This ensures if "Leg Stretch" is done 3 times, it only counts as 1
        let uniqueExercises = Set(todayCompletions.map { $0.exerciseName })
        
        return uniqueExercises.count
    }
    
    private var progressFraction: Double {
        let target = Double(viewModel.dailyTarget)
        return min(Double(completedTodayCount) / target, 1.0)
    }
    
    // MARK: - Badge Unlock Logic
    private func updateBadgeStatus() {
        let calendar = Calendar.current
        let completedDates = allCompletions.map { calendar.startOfDay(for: $0.completedAt) }
        let uniqueDaysCount = Set(completedDates).count
        
        let fetchDescriptor = FetchDescriptor<Badge>()
        
        do {
            let badges = try context.fetch(fetchDescriptor)
            
            for badge in badges {
                var shouldUnlock = false
                
                switch badge.imageName {
                case "badge1": if uniqueDaysCount >= 1 { shouldUnlock = true }
                case "badge2": if uniqueDaysCount >= 3 { shouldUnlock = true }
                case "badge3": if uniqueDaysCount >= 5 { shouldUnlock = true }
                case "badge4": if uniqueDaysCount >= 7 { shouldUnlock = true }
                case "badge5": if uniqueDaysCount >= 14 { shouldUnlock = true }
                case "badge6": if uniqueDaysCount >= 30 { shouldUnlock = true }
                default: break
                }
                
                if shouldUnlock && !badge.isUnlocked {
                    badge.isUnlocked = true
                    badge.unlockedAt = Date()
                }
            }
            // Safely save the updated badges
            try context.save()
        } catch {
            print("Database error: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 248/255, green: 251/255, blue: 248/255).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Welcome \(viewModel.userName)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.top, 8)
                        
                        exerciseProgressTab
                            .frame(maxWidth: .infinity, minHeight: 160)
                        
                        Text("Daily Challenge")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                        
                        challengeTab
                            .frame(maxWidth: .infinity, minHeight: 160)
                        
                        Text("Badges")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                        
                        BadgesCard()
                            .frame(height: 200)
                        
                        Spacer(minLength: 140)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                }
                bottomNavBar
            }
        }
        .environmentObject(viewModel)
        .onAppear { updateBadgeStatus() }
        .onChange(of: allCompletions) { updateBadgeStatus() }
        .task {
            do {
                _ = try Badge.ensureSeeded(in: context)
                updateBadgeStatus()
            } catch {
                print("Seeding failed: \(error)")
            }
        }
    }
}

// MARK: - Subview Definitions (Solves "Cannot find in scope")
private extension HomeView {
    var exerciseProgressTab: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 228/255, green: 239/255, blue: 235/255)).opacity(0.7)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    HStack(spacing: 14) {
                        Image(systemName: "figure.strengthtraining.traditional").font(.title2)
                        Text("Exercise Progress").font(.system(size: 26, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                    Text("\(completedTodayCount)/\(viewModel.dailyTarget)").font(.title3.bold())
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.1))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 235/255, green: 225/255, blue: 255/255))
                            .frame(width: geo.size.width * progressFraction)
                    }
                }
                .frame(height: 12)
                
                Text("\(Int(progressFraction * 100))%")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
    
    var challengeTab: some View {
        NavigationLink(destination: DailyChallengeView()) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 228/255, green: 239/255, blue: 235/255)).opacity(0.7)
                HStack(spacing: 20) {
                    Image(systemName: "flame.fill").font(.largeTitle).foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("Today's Daily Challenge").font(.headline).foregroundStyle(.secondary)
                        Text(Calendar.current.component(.day, from: Date()) % 2 == 0 ? "Puzzle Game" : "Memory Game")
                            .font(.title2.bold()).foregroundStyle(.black)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").bold().foregroundStyle(.secondary)
                }
                .padding(24)
            }
        }
        .buttonStyle(.plain)
    }
    
    var bottomNavBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 100) {
                navItem(title: "Exercise", img: "Bar", dest: ExerciseView())
                navItem(title: "Daily Challenge", img: "Fire2", dest: DailyChallengeView())
                navItem(title: "Calendar", img: "Calendar", dest: CalendarView())
                navItem(title: "Profile", img: "Profile", dest: ProfileView())
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color(red: 228/255, green: 239/255, blue: 235/255))
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
        .ignoresSafeArea()
    }
    
    func navItem(title: String, img: String, dest: some View) -> some View {
        NavigationLink(destination: dest) {
            VStack(spacing: 0) {
                Image(img).resizable().scaledToFill().frame(width: 80, height: 80)
                Text(title).font(.system(size: 17, design: .rounded)).foregroundStyle(.black)
            }
        }
    }
}

// MARK: - Shared BadgesCard Component
struct BadgesCard: View {
    @Query(sort: \Badge.imageName, order: .forward) private var badges: [Badge]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 228/255, green: 239/255, blue: 235/255)).opacity(0.7)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(badges) { badge in
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.4)).frame(width: 100, height: 100)
                                Image(badge.imageName)
                                    .resizable().scaledToFit().frame(width: 85, height: 85)
                                    .grayscale(badge.isUnlocked ? 0 : 1)
                                    .opacity(badge.isUnlocked ? 1 : 0.4)
                            }
                            Text(badge.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(badge.isUnlocked ? .black : .secondary)
                                .multilineTextAlignment(.center).frame(width: 100)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Badge.self])
}

