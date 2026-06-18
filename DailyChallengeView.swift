import SwiftUI

struct DailyChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAlreadyDone: Bool = ChallengeData.shared.isCompleted()
    
    private var isEvenDay: Bool {
        Calendar.current.component(.day, from: Date()) % 2 == 0
    }
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 251/255, blue: 248/255).ignoresSafeArea()
            
            if isAlreadyDone {
                // MARK: - FULL PAGE STATUS (Shown on second click)
                VStack(spacing: 25) {
                    ZStack {
                        Circle().fill(Color.black.opacity(0.05)).frame(width: 120, height: 120)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.black)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Challenge Complete!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("Great job! You've finished your brain exercise for today.\nCome back tomorrow for a new one!")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Back to Home") { dismiss() }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(width: 220, height: 55)
                        .background(Capsule().fill(Color.black.opacity(0.05)))
                }
                .transition(.opacity)
            } else {
                // MARK: - THE ACTIVE GAME
                if isEvenDay {
                    PuzzleGameView()
                    
                } else {
                    MemoryGameView()
                }
            }
        }
        // Updates state immediately if the game is finished while this view is active
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeUpdated"))) { _ in
            withAnimation {
                self.isAlreadyDone = ChallengeData.shared.isCompleted()
            }
        }
    }
}

#Preview {
    NavigationStack {
        DailyChallengeView()
    }
}

