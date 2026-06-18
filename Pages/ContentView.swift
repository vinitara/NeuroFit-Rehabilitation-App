import SwiftUI
import AVFoundation
import SwiftData

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking: Bool = false
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func speak(_ text: String, language: String? = nil) {
        configureAudioSession()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        let lang = language ?? AVSpeechSynthesisVoice.currentLanguageCode()
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivation error: \(error)")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}

// Essential helper struct
struct ExerciseDetails {
    let benefits: String
    let instructions: String
    let imageName: String
}

struct ContentView: View {
    let exercise: RehabExercise
    @State private var isCardVisible = true
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechManager()
    private var cameraInstructionText: String {
        // List the exercises that require Landscape or a different instruction
        if exercise.name == "Knee Extension" || exercise.name == "Hip Flexion with Hold" || exercise.name == "Seated Trunk Extension" || exercise.name == "Trunk Rotation" {
            return "Place iPad in landscape mode on the floor, stay 0.5 meters away so the camera sees your whole body"
        } else {
            // Your original default text
            return "Place iPad in portrait mode, stay 0.5 meters away and let your camera see half of your upper body"
        }
    }
    
    var body: some View {
        let details = getDetails(for: exercise.name)
        
        ZStack {
            Color(red: 248/255, green: 251/255, blue: 248/255)
                .ignoresSafeArea()
            
            if isCardVisible {
                // Main card container
                VStack(alignment: .leading, spacing: 25) {
                    
                    // 1. Title Only
                    Text(exercise.name)
                        .bold()
                        .font(.system(size: 45))
                        .fontDesign(.rounded)
                        .padding(.top, 20)
                    
                    // 2. Quick Info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Duration: \(String(format: "%.2f", Double(exercise.duration))) minutes")
                        Text("Targeted Regions: \(exercise.region)")
                    }
                    .font(.system(size: 26))
                    .fontDesign(.rounded)
                    .padding(.bottom, 2)
                    
                    /// 3. Camera Instruction Box
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(.secondary)
                            Text("Camera Instruction")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                        }
        
                        Text(cameraInstructionText)
                            .font(.system(size: 19))
                            .lineSpacing(0)
                            .kerning(-0.2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12) // Reduced from 20 to 12
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                    // 4. Benefits Box
                    VStack(alignment: .leading, spacing: 4) { // Reduced spacing from 10 to 4
                        HStack(spacing: 8) {
                            Text("Benefits of this exercise")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                            Button {
                                speakBenefits(details.benefits)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(details.benefits)
                            .font(.system(size: 19))
                            .lineSpacing(0) // Reduced from 6 to 0
                            .kerning(-0.2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 14) // Reduced from 24 to 14
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                    
                    // 5. How-To Box (With Aligned Numbered List)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("How to do this exercise")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                            Button {
                                speakInstructions(details.instructions)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Speak instructions")
                        }
                        
                        HStack(alignment: .top, spacing: 20) {
                            // Enlarged Image
                            Image(details.imageName) 
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180) 
                                .padding(10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            
                            // Instructions with hanging indent alignment
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(details.instructions.components(separatedBy: "\n"), id: \.self) { step in
                                    instructionRow(step: step)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    // 6. Start Button (Spacer removed to move it closer)
                    NavigationLink {
                        CameraView(
                            exerciseName: exercise.name,
                            durationMinutes: exercise.duration,
                            animationName: exercise.animationName
                        )
                    } label: {
                        Text("Start Exercise")
                            .fontDesign(.rounded)
                            .foregroundColor(.black)
                            .bold()
                            .font(.system(size: 22))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 248/255, green: 251/255, blue: 248/255))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.top, -10) // Small specific gap instead of a huge Spacer
                    .padding(.bottom, 30)
                }
                .padding(.top, 60)
                .padding(.horizontal, 40)
                .frame(width: 650, height: 900) 
                .background {
                    ZStack {
                        Color(red: 236/255, green: 244/255, blue: 239/255)
                        Color.white.opacity(0.35)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(radius: 25)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation { isCardVisible = false }
                        speech.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .padding(25)
                }
            }
        }
    }
    
    // Update your instructionRow helper as well
    private func instructionRow(step: String) -> some View {
        let components = step.split(separator: " ", maxSplits: 1)
        return HStack(alignment: .top, spacing: 8) {
            if components.count == 2 {
                Text(components[0])
                    .font(.system(size: 19, weight: .bold))
                    .frame(width: 25, alignment: .leading)
                
                Text(components[1])
                    .font(.system(size: 19))
                    .lineSpacing(0) // Reduced from 4 to 0
                    .kerning(-0.2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(step)
                    .font(.system(size: 19))
                    .kerning(-0.2)
            }
        }
    }
    
    // MARK: - Text to Speech
    private func speakBenefits(_ text: String) {
        speech.speak(text)
    }

    private func speakInstructions(_ instructions: String) {
        let steps = instructions
            .components(separatedBy: "\n")
            .map { line -> String in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let range = trimmed.range(of: "^[0-9]+[\\.\\)\\:]?\\s*", options: .regularExpression) {
                    return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                return trimmed
            }
            .filter { !$0.isEmpty }
        let combined = steps.joined(separator: ". ")
        speech.speak(combined)
    }

    private func speak(text: String) {
        // Kept for compatibility if called elsewhere
        speech.speak(text)
    }
    
    // MARK: - Private Database
    private func getDetails(for name: String) -> ExerciseDetails {
        switch name {
        case "Wrist Place and Hold":
            return ExerciseDetails(
                benefits: "Wrist place and hold exercise helps prevent or reduce wrist contractures and stimulates brain re-learning of movement. Regular practice improves wrist stability and helps regain control for hand use.",
                instructions: "1. Bring one arm forward\n2. Use the other hand to lift your wrist up\n3. Let go and try to hold the position for 4 seconds\n4. Relax after holding\n5. Repeat 10 times for each arm",
                imageName: "ex1"
            )
        case "Side Arm Raise":
            return ExerciseDetails(
                benefits: "Side arm raise exercise strengthens the shoulder and improves arm control. It helps restore the ability to reach, lift, and use the arm during daily activities.",
                instructions: "1. Stand or sit straight\n2. Lift your arm out to the side\n3. Raise to shoulder level if comfortable\n4. Keep shoulders relaxed\n5. Slowly lower your arm\n6. Repeat 15 times for each arm",
                imageName: "ex2"
            )
        case "Knee Extension":
            return ExerciseDetails(
                benefits: "Knee Extension exercise strengthens the thigh muscles and improves knee control. Stronger knees help support standing, walking, and reduce risk of falling.",
                instructions: "1. Sit on a chair\n2. Slowly straighten your knee\n3. Hold for 4 seconds\n4. Lower your leg slowly\n5. Repeat 15 times for each side",
                imageName: "ex3"
            )
        case "Trunk Rotation":
            return ExerciseDetails(
                benefits: "Trunk rotation exercise improves flexibility and coordination of the upper body. It helps stroke survivors turn their body more easily and maintain better balance.",
                instructions: "1. Sit upright\n2. Turn your upper body to one side\n3. Keep hips facing forward\n4. Return to center\n5. Repeat 10 times for each side",
                imageName: "ex4"
            )
        case "Wrist Bend Movement":
            return ExerciseDetails(
                benefits: "Wrist bend movement exercise helps reduce stiffness and hand spasticity after a stroke. With continued practice, wrist mobility improves, making daily hand movements easier.",
                instructions: "1. Bring one arm forward\n2. Bend wrist up slowly\n3. Then bend wrist down slowly\n4. Move only the wrist\n5. Repeat 15 times for each arm",
                imageName: "ex5"
            )
        case "Bicep Curl":
            return ExerciseDetails(
                benefits: "Bicept curl exercise is an important exercise which helps you regain the ability to bend your arm. It helps stroke survivors perform tasks like feeding and grooming independently",
                instructions: "1. Keep your arm straight in front\n2. Bend elbow to lift hand to shoulder\n3. Slowly straighten elbow\n4. Bring arm back to straight\n5. Repeat 15 times for each arm",
                imageName: "ex6"
            )
        case "Hip Flexion with Hold":
            return ExerciseDetails(
                benefits: "Hip flexion with hold strengthens the hip muscles and improves leg lifting ability. Stronger hips help with walking, stepping, and balance control.",
                instructions: "1. Sit straight in a chair\n2. Lift one knee up\n3. Hold for 4 seconds\n4. Slowly bring foot down\n5. Repeat 10 times for each leg",
                imageName: "ex7"
            )
        case "Seated Trunk Extension":
            return ExerciseDetails(
                benefits: "Seated trunk extension exercise strengthens the back muscles and improves posture. Better trunk control helps stroke survivors sit upright and maintain stability during movement.",
                instructions: "1. Sit upright\n2. Gently straighten and lift your chest\n3. Slightly arch your back\n4. Bring your chest towards the leg\n5. Return to normal sitting\n6. Repeat 15 times",
                imageName: "ex8"
            )
        default:
            return ExerciseDetails(
                benefits: "Seated trunk extension exercise strengthens the back muscles and improves posture. Better trunk control helps stroke survivors sit upright and maintain stability during movement.",
                instructions: "1. Sit upright\n2. Gently straighten and lift your chest\n3. Slightly arch your back\n4. Bring your chest towards the leg\n5. Return to normal sitting\n6. Repeat 15 times",
                imageName: "ex8"
            )
        }
    }
}


// MARK: - Preview
#Preview {
    NavigationStack {
        ContentView(
            exercise: RehabExercise(name: "Wrist Place and Hold", duration: 1.5, region: "Wrist", animationName: "ex1", isBilateral: true)
        )
    }
}

