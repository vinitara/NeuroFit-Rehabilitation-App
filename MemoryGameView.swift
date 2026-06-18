import SwiftUI

// MARK: - Model
struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
    var isFaceUp = false
    var isMatched = false
}

// MARK: - Main View
struct MemoryGameView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var cards: [MemoryCard] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var canInteract = true
    @State private var useSmallGrid = false 
    @State private var showingAnswers = false 
    @State private var showInstructions = false 
    
    // MARK: - Completion Tracking
    @State private var startTime = Date()
    @State private var timeTaken: String = "00:00"
    @State private var showCompletionPopUp = false
    
    // MARK: - Constants
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }
    
    private let allEmojis = ["🍎", "💪", "🏃‍♂️", "🧘‍♀️", "💧", "🥗", "🚴‍♂️", "🧗‍♀️", "🛌", "🧠", "🍊", "🍌"]
    private let mintColor = Color(red: 236/255, green: 244/255, blue: 239/255)
    private let purpleTheme = Color(red: 235/255, green: 225/255, blue: 255/255)
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 251/255, blue: 248/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                ZStack {
                    Rectangle()
                        .fill(purpleTheme)
                        .frame(height: 120)
                    
                    // Centered title
                    VStack(spacing: 2) {
                        Text("Memory Game")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Match cards in pairs")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(useSmallGrid ? "3x4 Grid" : "3x6 Grid")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.black)
                    .padding(.top, 40)
                    
                    // Trailing button layer
                    HStack {
                        Spacer()
                        Button {
                            showInstructions.toggle()
                        } label: {
                            Text("How To Play")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.black.opacity(0.06))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .popover(isPresented: $showInstructions) {
                            MemoryInstructionsView()
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 40)
                }
                .ignoresSafeArea(edges: .top)
                
                // MARK: - Centered Grid Container
                Spacer() 
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        cardView(for: index)
                    }
                }
                .padding(.horizontal, 35)
                
                Spacer() 
                
                // MARK: - Action Buttons
                HStack(spacing: 15) {
                    Button {
                        withAnimation(.spring()) {
                            useSmallGrid.toggle()
                            resetGame()
                        }
                    } label: {
                        HStack {
                            Image(systemName: useSmallGrid ? "plus.circle" : "minus.circle")
                            Text(useSmallGrid ? "Large Grid" : "Smaller Grid")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(mintColor))
                    }
                    
                    Button(action: {
                        if showingAnswers { dismiss() } else { giveUpAndReveal() }
                    }) {
                        Text(showingAnswers ? "Go Home" : "Give Up")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(showingAnswers ? .black : .red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.black.opacity(0.05)))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50) 
            }
            
            if showCompletionPopUp {
                completionOverlay
            }
        }
        .onAppear(perform: resetGame)
        .navigationBarHidden(true)
    }
    
    // MARK: - Helpers & Logic
    private func cardView(for index: Int) -> some View {
        ZStack {
            let card = cards[index]
            RoundedRectangle(cornerRadius: 15)
                .fill(card.isFaceUp || card.isMatched ? .white : mintColor)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black.opacity(0.05), lineWidth: 1))
            
            if card.isFaceUp || card.isMatched {
                Text(card.emoji).font(.system(size: 34))
            } else {
                Image(systemName: "brain.head.profile").font(.system(size: 24)).foregroundStyle(.gray.opacity(0.3))
            }
        }
        .frame(height: 90)
        .onTapGesture { flipCard(at: index) }
        .opacity(cards[index].isMatched ? 0.3 : 1.0)
        .rotation3DEffect(.degrees(cards[index].isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
    }
    
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 25) {
                ZStack {
                    Circle().fill(Color.black.opacity(0.05)).frame(width: 100, height: 100)
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 50)).foregroundStyle(.black)
                }
                VStack(spacing: 10) {
                    Text("Challenge Complete!").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.black)
                    Text("Time: \(timeTaken)").font(.title2.bold()).fontDesign(.rounded).foregroundStyle(.black)
                }
                Button(action: { dismiss() }) {
                    Text("Continue").font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black).frame(width: 220, height: 55).background(Capsule().fill(Color.black.opacity(0.05)))
                }
            }
            .padding(40).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
    
    private func flipCard(at index: Int) {
        guard canInteract, !cards[index].isFaceUp, !cards[index].isMatched else { return }
        cards[index].isFaceUp = true
        if let first = firstSelectedIndex {
            if cards[index].emoji == cards[first].emoji {
                cards[index].isMatched = true; cards[first].isMatched = true
                firstSelectedIndex = nil; checkWin()
            } else {
                canInteract = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    cards[index].isFaceUp = false; cards[first].isFaceUp = false
                    firstSelectedIndex = nil; canInteract = true
                }
            }
        } else { firstSelectedIndex = index }
    }
    
    private func resetGame() {
        showingAnswers = false; showCompletionPopUp = false; startTime = Date()
        let pairCount = useSmallGrid ? 6 : 9
        let selectedEmojis = Array(allEmojis.shuffled().prefix(pairCount))
        let paired = (selectedEmojis + selectedEmojis).shuffled()
        cards = paired.map { MemoryCard(emoji: $0) }
        firstSelectedIndex = nil; canInteract = true
    }
    
    private func giveUpAndReveal() {
        canInteract = false; showingAnswers = true 
        for i in 0..<cards.count { cards[i].isFaceUp = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { if showingAnswers { dismiss() } }
    }
    
    private func checkWin() {
        if cards.allSatisfy({ $0.isMatched }) {
            let diff = Int(Date().timeIntervalSince(startTime))
            timeTaken = String(format: "%02d:%02d", diff / 60, diff % 60)
            ChallengeData.shared.markAsCompleted()
            // Log Daily Challenge completion for CalendarView
            do {
                let df = DateFormatter()
                df.calendar = Calendar(identifier: .gregorian)
                df.dateFormat = "yyyy-MM-dd"
                let key = df.string(from: Date())
                let storageKey = "challenge.completionLog"
                let defaults = UserDefaults.standard
                let existing = defaults.string(forKey: storageKey) ?? "{}"
                var dict: [String: Bool] = (try? JSONSerialization.jsonObject(with: Data(existing.utf8)) as? [String: Bool]) ?? [:]
                dict[key] = true
                if let data = try? JSONSerialization.data(withJSONObject: dict),
                   let str = String(data: data, encoding: .utf8) {
                    defaults.set(str, forKey: storageKey)
                }
            }
            withAnimation(.spring()) { showCompletionPopUp = true }
        }
    }
}

// MARK: - Supporting Views
struct MemoryInstructionRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).font(.title3).frame(width: 30)
            Text(text).font(.system(size: 16, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}

struct MemoryInstructionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to Play").font(.system(size: 24, weight: .bold, design: .rounded))
            VStack(alignment: .leading, spacing: 15) {
                MemoryInstructionRow(icon: "square.grid.2x2", text: "Tap a card to reveal the emoji underneath.")
                MemoryInstructionRow(icon: "arrow.2.squarepath", text: "Find matching pairs to clear the board.")
                MemoryInstructionRow(icon: "checkmark.seal", text: "Match everything to earn your daily badge!")
            }
        }.padding(30).frame(width: 350)
    }
}
#Preview {
    MemoryGameView()
}

