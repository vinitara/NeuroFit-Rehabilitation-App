import SwiftUI
import SwiftData
import AVFoundation
import Combine

private let repTargetsByName: [String: Int] = [
    "Wrist Place and Hold": 10,
    "Side Arm Raise": 15,
    "Knee Extension": 15,
    "Trunk Rotation": 10,
    "Wrist Bend Movement": 15,
    "Bicep Curl": 15,
    "Hip Flexion with Hold": 10,
    "Seated Trunk Extension": 15
]

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exerciseName: String
    let durationMinutes: Double
    let animationName: String
    
    @StateObject private var cameraCoordinator = CameraCoordinator()
    
    @State private var remainingSeconds: Int = 0
    @State private var preCountdownSeconds: Int = 5
    @State private var isPreCountdownActive: Bool = true
    @State private var showCompletionPopup: Bool = false
    @State private var isPaused: Bool = false
    @State private var showPauseOptions: Bool = false
    @State private var repCount: Int = 0
    @State private var targetRepsPerSide: Int = 10
    @State private var isAuthorized = false
    
    @State private var currentSide: String = "RIGHT"
    @State private var isRightSideComplete = false
    @State private var movementUp = false
    
    @State private var lastHoldTime = Date.distantPast
    @State private var holdStarted = false
    @State private var debugMessage: String = ""
    @State private var lastDebugUpdate = Date.distantPast
    
    @State private var beepPlayer: AVAudioPlayer? = nil
    @State private var beepName: String = "beepbeep"

    @State private var showSideSwitchPopup: Bool = false
    @State private var sideSwitchMessage: String = ""

    
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let purpleTheme = Color(red: 235/255, green: 225/255, blue: 255/255)
    
    init(exerciseName: String, durationMinutes: Double, animationName: String) {
        self.exerciseName = exerciseName
        self.durationMinutes = durationMinutes
        self.animationName = animationName
        _remainingSeconds = State(initialValue: Int(durationMinutes * 60))
    }
    
    var body: some View {
        ZStack {
            // 1. Camera
            if isAuthorized {
                CameraPreview(session: cameraCoordinator.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                Text("Camera Access Required").foregroundColor(.white)
            }
            
            // 2. Main UI Layout
            VStack(spacing: 0) {
                headerView
                
                HStack(alignment: .top) {
                    if !isPreCountdownActive && !showCompletionPopup {
                        exerciseInstructionOverlay
                            .padding(.leading, 20)
                            .padding(.top, 20)
                    }
                    Spacer()
                }
                Spacer() // Pushes everything above to the top
            }
            
            // Side switch popup overlay
            if showSideSwitchPopup {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 14) {
                        Text(sideSwitchMessage)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
                    }
                }
                .transition(.opacity)
            }
            
            // 3. Floating Pause Button (Bottom Center)
            if !isPreCountdownActive && !showCompletionPopup && !isPaused {
                VStack {
                    Spacer()
                    pauseButton
                        .padding(.bottom, 50) // Moved up slightly to be visible
                }
            }

            // Pause Options Overlay when paused
            if isPaused && !isPreCountdownActive && !showCompletionPopup {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Button(action: {
                                // Continue
                                isPaused = false
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                    Text("Continue")
                                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 22)
                                .background(
                                    Capsule().fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
                            }

                            Button(action: {
                                // Exit without saving completion
                                dismiss()
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                    Text("Exit")
                                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 22)
                                .background(
                                    Capsule().fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Debug guidance overlay
            if !debugMessage.isEmpty && !showCompletionPopup {
                VStack {
                    Spacer()
                    Text(debugMessage)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 22)
                        .background(
                            Capsule().fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
                        .padding(.bottom, 140)
                }
                .transition(.opacity)
            }
            
            // 4. Overlays
            if isPreCountdownActive { countdownOverlay }
            if showCompletionPopup { completionPopupView }
        }
        .navigationBarHidden(true)
        .onAppear {
            prepareAudioPlayers()
            startSequence()
        }
        .onDisappear { cameraCoordinator.stopSession() }
        .onReceive(clockTimer) { _ in handleTimerTick() }
    }
}

// MARK: - Logic Implementation
private extension CameraView {
    
    func startSequence() {
        cameraCoordinator.requestAuthorizationIfNeeded { granted in
            self.isAuthorized = granted
            if granted {
                cameraCoordinator.configureSession()
                cameraCoordinator.exerciseType = determineType(from: exerciseName)
                targetRepsPerSide = repTargetsByName[exerciseName] ?? 10
                cameraCoordinator.currentSide = currentSide
                cameraCoordinator.onPoseDetected = { state in
                    self.handleAIPose(state)
                }
                cameraCoordinator.startSession()
            }
        }
    }
    
    func determineType(from name: String) -> ExerciseType {
        switch name {
        case "Wrist Place and Hold":
            return .wristHold
        case "Side Arm Raise":
            return .sideArmRaise
        case "Knee Extension":
            return .kneeExtension
        case "Trunk Rotation":
            return .trunkRotation
        case "Wrist Bend Movement":
            return .wristBend
        case "Bicep Curl":
            return .bicepCurl
        case "Hip Flexion with Hold":
            return .hipFlexion
        case "Seated Trunk Extension":
            return .seatedTrunkExtension
        default:
            return .sideArmRaise
        }
    }
    
    func handleAIPose(_ state: ArmState) {
        guard !isPreCountdownActive && !isPaused && !showCompletionPopup else { return }
        
        DispatchQueue.main.async {
            switch state {
            case .hold:
                // Logic for 4-second HOLD exercises
                if exerciseName.contains("Hold") || exerciseName.contains("Rotation") {
                    if !holdStarted {
                        lastHoldTime = Date()
                        holdStarted = true
                    }
                    let elapsed = Date().timeIntervalSince(lastHoldTime)
                    if elapsed >= 4.0 {
                        countRep()
                        holdStarted = false // Reset for next hold
                        debugMessage = "Hold complete — great job!"
                    } else {
                        debugMessage = String(format: "Hold steady… %.0fs", 4.0 - elapsed)
                    }
                } else {
                    // Priming for movement exercises (Trunk Extension, etc.)
                    movementUp = true
                    debugMessage = "Hold steady, then move"
                }
                
            case .up:
                holdStarted = false
                // Count movement if it was primed by a hold/down state
                if movementUp { countRep() }
                // Guidance per exercise
                if exerciseName.contains("Side Arm Raise") { debugMessage = "Good — arm up" }
                else if exerciseName.contains("Bicep Curl") { debugMessage = "Curl up" }
                else if exerciseName.contains("Knee Extension") { debugMessage = "Extend knee" }
                else if exerciseName.contains("Hip Flexion") { debugMessage = "Lift knee" }
                else if exerciseName.contains("Wrist Bend") { debugMessage = "Bend wrist up" }
                else if exerciseName.contains("Seated Trunk") { debugMessage = "Extend trunk" }
                else { debugMessage = "Good — up" }
                
            case .down:
                holdStarted = false
                // Prime the next rep for movement-based exercises
                movementUp = true
                // Guidance per exercise
                if exerciseName.contains("Side Arm Raise") { debugMessage = "Lower arm" }
                else if exerciseName.contains("Bicep Curl") { debugMessage = "Lower slowly" }
                else if exerciseName.contains("Knee Extension") { debugMessage = "Lower leg" }
                else if exerciseName.contains("Hip Flexion") { debugMessage = "Lower knee" }
                else if exerciseName.contains("Wrist Bend") { debugMessage = "Relax wrist" }
                else if exerciseName.contains("Seated Trunk") { debugMessage = "Return to start" }
                else { debugMessage = "Down" }
                
            case .wrong:
                holdStarted = false
                movementUp = false
                // Specific guidance for wrong posture
                if exerciseName.contains("Trunk Rotation") { debugMessage = "Rotate more to hold" }
                else if exerciseName.contains("Wrist Place and Hold") { debugMessage = "Keep wrist aligned with shoulder" }
                else { debugMessage = "Adjust form" }
            }
        }
    }
    
    func countRep() {
        repCount += 1
        movementUp = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if repCount >= targetRepsPerSide {
            handleSideSwitch()
        }
    }
    
    func isBilateralExercise(_ name: String) -> Bool {
        switch name {
        case "Side Arm Raise",
             "Bicep Curl",
             "Knee Extension",
             "Wrist Bend Movement",
             "Wrist Place and Hold",
             "Hip Flexion with Hold",
             "Trunk Rotation":
            return true
        case "Seated Trunk Extension":
            return false
        default:
            return true
        }
    }
    
    func handleSideSwitch() {
        let bilateral = isBilateralExercise(exerciseName)
        if bilateral {
            if !isRightSideComplete {
                // Switch to left side and continue
                isRightSideComplete = true
                repCount = 0
                currentSide = "LEFT"
                cameraCoordinator.currentSide = "LEFT"
                // Show side switch popup with beep
                sideSwitchMessage = "Switch to Right Side"
                withAnimation(.easeInOut(duration: 0.2)) { showSideSwitchPopup = true }
                playFinal()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation(.easeInOut(duration: 0.2)) { showSideSwitchPopup = false }
                }
            } else {
                // Both sides completed -> finish immediately
                saveAndFinish()
            }
        } else {
            // Single-side exercise -> finish immediately when reps target reached
            saveAndFinish()
        }
    }
    
    func handleTimerTick() {
        guard !isPaused && !showCompletionPopup else { return }
        if isPreCountdownActive {
            if preCountdownSeconds > 1 {
                preCountdownSeconds -= 1
                playTick()
            } else if preCountdownSeconds == 1 {
                preCountdownSeconds -= 1
                playFinal()
            } else {
                isPreCountdownActive = false
            }
        } else {
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                saveAndFinish()
            }
        }
    }
    
    func restartSession() {
        repCount = 0
        isRightSideComplete = false
        currentSide = "RIGHT"
        cameraCoordinator.currentSide = "RIGHT"
        movementUp = false
        holdStarted = false
        lastHoldTime = .distantPast
        remainingSeconds = Int(durationMinutes * 60)
        preCountdownSeconds = 5
        isPreCountdownActive = true
        isPaused = false
    }
    
    func saveAndFinish() {
        cameraCoordinator.stopSession()
        let newCompletion = ExerciseCompletion(
            exerciseName: exerciseName,
            completedAt: Date(),
            durationInMinutes: Int(durationMinutes),
            animationName: animationName
        )
        modelContext.insert(newCompletion)
        
        withAnimation(.spring()) {
            showCompletionPopup = true
        }
    }
    
    func prepareAudioPlayers() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: beepName, withExtension: "mp3") {
            beepPlayer = try? AVAudioPlayer(contentsOf: url)
            beepPlayer?.prepareToPlay()
        }
    }

    func playTick() { beepPlayer?.currentTime = 0; beepPlayer?.play() }
    func playFinal() { playTick() }
}

// MARK: - UI Subviews
private extension CameraView {
    
    var headerView: some View {
        ZStack {
            Rectangle()
                .fill(purpleTheme)
                .frame(height: 120)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                }
                Spacer()
                Text(formatTime(remainingSeconds))
                    .font(.system(size: 27, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.8)))
            }
            .padding(.horizontal, 25)
            .padding(.top, 40)
        }
        .ignoresSafeArea()
    }
    
    var exerciseInstructionOverlay: some View {
        VStack(spacing: 12) {
            Image(animationName)
                .resizable()
                .scaledToFill()
                .frame(width: 190, height: 200)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 6) {
                if (currentSide=="LEFT"){
                    Text("Right Side")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                else{
                    Text("Left Side")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                
                Text("\(repCount)/\(targetRepsPerSide)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.9)
                
                Text("REPS")
                    .font(.caption).bold()
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .frame(width: 220) // Fixed card width for consistent coverage
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .offset(y: -30)
    }
    
    var pauseButton: some View {
        Button(action: {
            isPaused = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 26, weight: .semibold))
                Text(isPaused ? "RESUME" : "PAUSE")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 44)
            .padding(.vertical, 22)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 8)
        }
    }
    
    var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 16)
                    .frame(width: 200, height: 200)
                Text("\(preCountdownSeconds)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    var completionPopupView: some View {
        ZStack {
            // Dimmed backdrop to focus attention on the pop-up
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.85))

                // Text
                VStack(spacing: 8) {
                    Text("Great Work!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.9))

                    Text("Session Complete")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
                .multilineTextAlignment(.center)

                // Action
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.9))
                        .frame(width: 220, height: 52)
                        .background(
                            Capsule().fill(Color.black.opacity(0.06))
                        )
                }
            }
            .padding(36)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            .padding(.horizontal, 28)
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// Updated Preview to match new init
//new version 5
#Preview {
    CameraView(exerciseName: "Wrist Place and Hold", durationMinutes: 1, animationName: "ex1")
}

