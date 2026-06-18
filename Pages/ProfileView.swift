import SwiftUI
import SwiftData

struct ProfileView: View {
    @AppStorage("profile.name") private var storedName: String = "Jane"
    @AppStorage("profile.age") private var storedAge: Int = 25
    @AppStorage("profile.gender") private var storedGender: String = "Female"
    @AppStorage("profile.heightCm") private var storedHeightCm: Double = 170
    @AppStorage("profile.weightKg") private var storedWeightKg: Double = 65
    
    @State private var name: String = ""
    @State private var ageText: String = ""
    @State private var gender: String = "Female"
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var isEditing: Bool = false
    
    @State private var calculatedBMI: Double? = nil
    @State private var calculatedCategory: String = "--"
    
    private let mintColor = Color(red: 236/255, green: 244/255, blue: 239/255)
    
    init() {
        _name = State(initialValue: storedName)
        _ageText = State(initialValue: String(storedAge))
        _gender = State(initialValue: storedGender)
        _heightText = State(initialValue: String(format: "%.1f", storedHeightCm))
        _weightText = State(initialValue: String(format: "%.1f", storedWeightKg))
    }
    
    private func color(for category: String) -> Color {
        switch category {
        case "Underweight": return Color(red: 233/255, green: 224/255, blue: 247/255)
        case "Healthy Weight": return Color(red: 211/255, green: 232/255, blue: 227/255)
        case "At Risk": return Color(red: 255/255, green: 239/255, blue: 200/255)
        case "Overweight": return Color(red: 255/255, green: 215/255, blue: 215/255)
        default: return Color.gray.opacity(0.2)
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 251/255, blue: 248/255).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("\(storedName)'s Profile")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                        Button {
                            if isEditing { saveProfile() } else { isEditing = true }
                        } label: {
                            Text(isEditing ? "Save" : "Edit")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20).padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        FieldBlock(label: "Name", value: storedName, text: $name, isEditing: isEditing)
                        FieldBlock(label: "Age", value: "\(storedAge) years", text: $ageText, isEditing: isEditing, keyboard: .numberPad)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Gender").font(.system(size: 18)).foregroundStyle(.secondary)
                            if isEditing {
                                Picker("Gender", selection: $gender) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                }.pickerStyle(.segmented)
                            } else {
                                Text(storedGender).font(.system(size: 24, weight: .bold, design: .rounded))
                            }
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(mintColor).opacity(0.7))
                        
                        FieldBlock(label: "Height (cm)", value: String(format: "%.1f cm", storedHeightCm), text: $heightText, isEditing: isEditing, keyboard: .decimalPad)
                        FieldBlock(label: "Weight (kg)", value: String(format: "%.1f kg", storedWeightKg), text: $weightText, isEditing: isEditing, keyboard: .decimalPad)
                    }
                    
                    Text("BMI").font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    BMICalculatorCard(
                        storedHeightCm: storedHeightCm, 
                        storedWeightKg: storedWeightKg,
                        calculatedBMI: $calculatedBMI, 
                        calculatedCategory: $calculatedCategory,
                        categoryColor: color(for: calculatedCategory)
                    )
                    
                    ProfileBadgesCard()
                }
                .padding(20)
            }
        }
    }
    
    private func saveProfile() {
        storedName = name
        storedGender = gender
        if let age = Int(ageText) { storedAge = age }
        storedHeightCm = Double(heightText.replacingOccurrences(of: ",", with: ".")) ?? storedHeightCm
        storedWeightKg = Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? storedWeightKg
        isEditing = false
    }
}

// MARK: - Profile Achievements View
private struct ProfileBadgesCard: View {
    @Query(sort: \Badge.imageName, order: .forward) private var badges: [Badge]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Badges").font(.system(size: 28, weight: .bold, design: .rounded))
            
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color(red: 236/255, green: 244/255, blue: 239/255).opacity(0.7))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(badges) { badge in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.6)).frame(width: 100, height: 100)
                                    .overlay(
                                        Image(badge.imageName)
                                            .resizable().scaledToFit().frame(width: 85, height: 85)
                                            .grayscale(badge.isUnlocked ? 0 : 1)
                                            .opacity(badge.isUnlocked ? 1 : 0.5)
                                    )
                                Text(badge.title)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(badge.isUnlocked ? .black : .secondary)
                                    .multilineTextAlignment(.center).frame(width: 100, height: 40, alignment: .top)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Helper Structs
private struct FieldBlock: View {
    let label: String
    let value: String
    @Binding var text: String
    let isEditing: Bool
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 18)).foregroundStyle(.secondary)
            if isEditing {
                TextField("", text: $text).keyboardType(keyboard)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.5)))
            } else {
                Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 236/255, green: 244/255, blue: 239/255)).opacity(0.7))
    }
}

private struct BMICalculatorCard: View {
    var storedHeightCm: Double
    var storedWeightKg: Double
    @Binding var calculatedBMI: Double?
    @Binding var calculatedCategory: String
    var categoryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Height: \(String(format: "%.1f", storedHeightCm)) cm")
                Spacer()
                Text("Weight: \(String(format: "%.1f", storedWeightKg)) kg")
            }
            .font(.system(size: 20, weight: .medium))
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BMI").font(.system(size: 16)).foregroundStyle(.secondary)
                    Text(calculatedBMI != nil ? String(format: "%.1f", calculatedBMI!) : "--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }
                Spacer()
                Text(calculatedCategory).font(.system(size: 18, weight: .bold)) 
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(categoryColor).clipShape(Capsule())
            }
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 236/255, green: 244/255, blue: 239/255).opacity(0.7)))
        .onAppear { recalc() }
        .onChange(of: storedHeightCm) { recalc() }
        .onChange(of: storedWeightKg) { recalc() }
    }
    
    private func recalc() {
        let meters = storedHeightCm / 100
        if meters > 0, storedWeightKg > 0 {
            let val = storedWeightKg / (meters * meters)
            calculatedBMI = val
            if val < 18.5 { calculatedCategory = "Underweight" }
            else if val < 23 { calculatedCategory = "Healthy Weight" }
            else if val < 25 { calculatedCategory = "At Risk" }
            else { calculatedCategory = "Overweight" }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [ExerciseEntry.self, ExerciseCompletion.self, Badge.self], inMemory: true)
}

