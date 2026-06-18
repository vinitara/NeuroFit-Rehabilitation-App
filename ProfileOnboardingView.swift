import SwiftUI

struct ProfileOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("profile.name") private var storedName: String = ""
    
    var onContinue: ((UserProfile) -> Void)? = nil
    
    private let appBackground = Color(red: 248/255, green: 251/255, blue: 248/255)
    private let cardTint = Color(red: 236/255, green: 244/255, blue: 239/255)
    
    @State private var name: String = ""
    @State private var ageText: String = ""
    @State private var gender: String = "Male"
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    
    private let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        ZStack {
            appBackground.ignoresSafeArea()
            
            VStack {
                Spacer() // 1. Pushes content down from the top
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) { // Increased spacing between header and card
                        
                        // Header
                        VStack(spacing: 12) {
                            Text("Welcome to NeuroFit")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Start your rehabilitation journey today!")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // The Form Rectangle
                        VStack(alignment: .leading, spacing: 18) {
                            formField(title: "Name", prompt: "Required", text: $name)
                            formField(title: "Age", prompt: "Optional", text: $ageText, keyboard: .numberPad)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gender").font(.caption).bold().foregroundStyle(.secondary)
                                Picker("Gender", selection: $gender) {
                                    ForEach(genders, id: \.self) { Text($0).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            
                            formField(title: "Height (cm)", prompt: "Optional", text: $heightText, keyboard: .decimalPad)
                            formField(title: "Weight (kg)", prompt: "Optional", text: $weightText, keyboard: .decimalPad)
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.black.opacity(0.06)))
                        .shadow(color: .black.opacity(0.03), radius: 10, y: 5)
                        
                        // Continue button
                        Button(action: continueTapped) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: 220)
                                .background(name.isEmpty ? Color.gray : Color.black)
                                .clipShape(Capsule())
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding(24)
                }
                .fixedSize(horizontal: false, vertical: true) // 2. Tells ScrollView to take only as much space as needed
                
                Spacer() // 3. Pushes content up from the bottom
            }
        }
    }
    
    private func formField(title: String, prompt: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).bold().foregroundStyle(.secondary)
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
        }
    }
    
    private func continueTapped() {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: Int(ageText),
            gender: gender,
            heightCm: Double(heightText),
            weightKg: Double(weightText)
        )
        onContinue?(profile)
        storedName = profile.name
        hasCompletedOnboarding = true
        dismiss()
    }
}
#Preview {
    NavigationStack {
        ProfileOnboardingView()
    }
}
