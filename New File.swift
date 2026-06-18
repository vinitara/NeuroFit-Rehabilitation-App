import SwiftUI

struct LandingPageView: View {
    
    // Navigation
    @State private var goToHome = false
    
    // Form state
    @State private var name: String = ""
    @State private var ageText: String = ""
    @State private var gender: String = "Male"
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    
    private let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 248/255, green: 251/255, blue: 248/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // MARK: Header
                        VStack(spacing: 12) {
                            Text("Welcome to NeuroFit")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            
                            Text("Start your rehabilitation journey today!")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // MARK: Form Card
                        VStack(alignment: .leading, spacing: 18) {
                            
                            formField(title: "Name", prompt: "Required", text: $name)
                            
                            formField(title: "Age", prompt: "Optional",
                                      text: $ageText,
                                      keyboard: .numberPad)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gender")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                
                                Picker("Gender", selection: $gender) {
                                    ForEach(genders, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            formField(title: "Height (cm)", prompt: "Optional",
                                      text: $heightText,
                                      keyboard: .decimalPad)
                            
                            formField(title: "Weight (kg)", prompt: "Optional",
                                      text: $weightText,
                                      keyboard: .decimalPad)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.black.opacity(0.06))
                        )
                        
                        // MARK: Continue Button
                        Button {
                            saveProfile()
                            goToHome = true
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: 220)
                                .background(name.isEmpty ? Color.gray : Color.black)
                                .clipShape(Capsule())
                        }
                        .disabled(name.isEmpty)
                        
                        NavigationLink("", destination: HomeView(), isActive: $goToHome)
                            .hidden()
                    }
                    .padding(24)
                }
            }
        }
    }
    
    // MARK: Form Field
    private func formField(
        title: String,
        prompt: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
            
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
        }
    }
    
    // MARK: Save to AppStorage
    private func saveProfile() {
        UserDefaults.standard.set(name, forKey: "profile.name")
        UserDefaults.standard.set(Int(ageText) ?? 0, forKey: "profile.age")
        UserDefaults.standard.set(gender, forKey: "profile.gender")
        UserDefaults.standard.set(Double(heightText) ?? 0, forKey: "profile.heightCm")
        UserDefaults.standard.set(Double(weightText) ?? 0, forKey: "profile.weightKg")
    }
}
