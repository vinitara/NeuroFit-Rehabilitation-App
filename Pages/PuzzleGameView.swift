import SwiftUI

struct PuzzleTile: Identifiable, Equatable {
    let id: Int
    var currentPosition: Int
}

struct PuzzleGameView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var tiles: [PuzzleTile] = []
    @State private var canInteract = true
    @State private var showingAnswers = false
    @State private var moveCount = 0
    @State private var startTime = Date()
    @State private var timeTaken: String = "00:00"
    @State private var showCompletionPopUp = false
    @State private var showInstructions = false 
    
    private let gridSize = 4 
    private let mintColor = Color(red: 236/255, green: 244/255, blue: 239/255)
    private let purpleTheme = Color(red: 235/255, green: 225/255, blue: 255/255)
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 248/255, green: 251/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header (Isolated Height to prevent layout lag)
                // MARK: - FIXED HEADER
                ZStack {
                    // 1. The Background Bar
                    Rectangle()
                        .fill(purpleTheme)
                        .frame(height: 140) // Fixed height prevents layout "jumps"
                    
                    // Centered title
                    VStack(spacing: 2) {
                        Text("15 Puzzle")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        Text("Order tiles 1–15, left to right • Moves: \(moveCount)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
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
                            PuzzleInstructionsView()
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.top, 40)
                }
                .ignoresSafeArea(edges: .top) // Ensures the purple color goes behind the notch/status bar
                
                Spacer() 
                
                // MARK: - Puzzle Grid (Optimized for iPad Performance)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<16, id: \.self) { position in
                        tileView(for: position)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
                .padding(.horizontal, 25)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 20) // Higher threshold = less accidental "glitchy" movement
                        .onEnded { gesture in 
                            if canInteract { handleSwipe(translation: gesture.translation) }
                        }
                )
                
                Spacer() 
                
                // MARK: - Bottom Action Bar
                HStack(spacing: 15) {
                    Button(action: resetGame) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Redo")
                        }
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(mintColor))
                    }
                    .disabled(showCompletionPopUp) 
                    
                    Button(action: { if showingAnswers { dismiss() } else { giveUpAndReveal() } }) {
                        Text(showingAnswers ? "Go Home" : "Give Up")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(showingAnswers ? .black : Color.red.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.black.opacity(0.05)))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50) 
            }
            
            // Completion Pop-up Overlay
            if showCompletionPopUp {
                Color.black.opacity(0.15).ignoresSafeArea()
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onAppear(perform: resetGame)
        .navigationBarHidden(true)
    }
    
    // MARK: - View Helpers
    @ViewBuilder
    private func tileView(for position: Int) -> some View {
        if let tile = tiles.first(where: { $0.currentPosition == position }), tile.id != 0 {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                Text("\(tile.id)").font(.system(size: 28, weight: .bold, design: .rounded))
            }
        } else {
            RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.05))
        }
    }
    
    private var completionOverlay: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle().fill(Color.black.opacity(0.05)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 50)).foregroundStyle(.black)
            }
            VStack(spacing: 10) {
                Text("Puzzle Solved!").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.black)
                Text("Time: \(timeTaken)").font(.title2.bold()).fontDesign(.rounded).foregroundStyle(.black)
            }
            Button(action: { dismiss() }) {
                Text("Continue").font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black).frame(width: 220, height: 55)
                    .background(Capsule().fill(Color.black.opacity(0.05)))
            }
        }
        .padding(40).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 30))
    }
    
    // MARK: - Game Logic
    private func resetGame() {
        var numbers = Array(0...15)
        repeat { numbers.shuffle() } while !isSolvable(numbers)
        tiles = numbers.enumerated().map { PuzzleTile(id: $1, currentPosition: $0) }
        moveCount = 0; showingAnswers = false; showCompletionPopUp = false; startTime = Date(); canInteract = true
    }
    
    private func handleSwipe(translation: CGSize) {
        guard let emptyTile = tiles.first(where: { $0.id == 0 }) else { return }
        let ePos = emptyTile.currentPosition
        let eRow = ePos / gridSize
        let eCol = ePos % gridSize
        var targetPosition: Int?
        
        if abs(translation.width) > abs(translation.height) {
            if translation.width > 0 { if eCol > 0 { targetPosition = ePos - 1 } }
            else { if eCol < 3 { targetPosition = ePos + 1 } }
        } else {
            if translation.height > 0 { if eRow > 0 { targetPosition = ePos - gridSize } }
            else { if eRow < 3 { targetPosition = ePos + gridSize } }
        }
        
        if let pos = targetPosition, let tileToMove = tiles.first(where: { $0.currentPosition == pos }) {
            moveTile(tileToMove)
        }
    }
    
    private func moveTile(_ tile: PuzzleTile) {
        guard let emptyTile = tiles.first(where: { $0.id == 0 }) else { return }
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.75)) {
            let oldPos = tile.currentPosition
            if let index = tiles.firstIndex(where: { $0.id == tile.id }),
               let emptyIndex = tiles.firstIndex(where: { $0.id == 0 }) {
                tiles[index].currentPosition = emptyTile.currentPosition
                tiles[emptyIndex].currentPosition = oldPos
                moveCount += 1
                checkWin()
            }
        }
    }
    
    private func checkWin() {
        let isWon = tiles.allSatisfy { tile in
            if tile.id == 0 { return tile.currentPosition == 15 }
            return tile.currentPosition == (tile.id - 1)
        }
        if isWon {
            canInteract = false
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
            let diff = Int(Date().timeIntervalSince(startTime))
            timeTaken = String(format: "%02d:%02d", diff / 60, diff % 60)
            withAnimation(.spring()) { showCompletionPopUp = true }
        }
    }
    
    private func giveUpAndReveal() {
        canInteract = false; showingAnswers = true
        withAnimation(.spring()) {
            for i in 1...15 { if let idx = tiles.firstIndex(where: { $0.id == i }) { tiles[idx].currentPosition = i - 1 } }
            if let emptyIndex = tiles.firstIndex(where: { $0.id == 0 }) { tiles[emptyIndex].currentPosition = 15 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { if showingAnswers { dismiss() } }
    }
    
    private func isSolvable(_ puzzle: [Int]) -> Bool {
        var inversions = 0
        let flat = puzzle.filter { $0 != 0 }
        for i in 0..<flat.count {
            for j in i + 1..<flat.count {
                if flat[i] > flat[j] { inversions += 1 }
            }
        }
        let emptyIndex = puzzle.firstIndex(of: 0)!
        let emptyRowFromBottom = gridSize - (emptyIndex / gridSize)
        return (gridSize % 2 != 0) ? (inversions % 2 == 0) : ((inversions + emptyRowFromBottom) % 2 != 0)
    }
}

// MARK: - Instructions View
struct PuzzleInstructionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to Play").font(.system(size: 24, weight: .bold, design: .rounded))
            VStack(alignment: .leading, spacing: 15) {
                PuzzleInstructionRow(icon: "hand.draw", text: "Swipe tiles horizontally or vertically to move them into the empty space.")
                PuzzleInstructionRow(icon: "list.number", text: "Arrange the numbers in order from 1 to 15, starting from the top-left.")
                PuzzleInstructionRow(icon: "trophy", text: "Complete the grid to unlock your badge!")
            }
        }.padding(30).frame(width: 380)
    }
}

struct PuzzleInstructionRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).font(.title3).frame(width: 30)
            Text(text).font(.system(size: 16, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PuzzleGameView()
}

