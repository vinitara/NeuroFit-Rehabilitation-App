import SwiftUI
import SwiftData

struct CalendarView: View {
    // MARK: - UI State
    @State private var selectedDate: Date = {
        var cal = Calendar(identifier: .gregorian)
        return cal.startOfDay(for: .now)
    }()
    @State private var isLoggingSymptoms: Bool = false
    @State private var symptomNotes: String = ""
    
    // MARK: - Persistent Storage
    @AppStorage("profile.name") private var storedName: String = "Jane"
    @AppStorage("calendar.symptoms") private var storedSymptomsJSON: String = "{}"
    @AppStorage("challenge.completionLog") private var completedChallengesJSON: String = "{}"
    
    // MARK: - SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ExerciseCompletion.completedAt, order: .reverse)]) 
    private var allCompletions: [ExerciseCompletion]
    
    // MARK: - Colors
    private let lightCardColor = Color(red: 236/255, green: 244/255, blue: 239/255)
    private let purpleHighlight = Color(red: 233/255, green: 224/255, blue: 247/255)
    
    // MARK: - Computed Properties
    private var completionsForSelectedDate: [ExerciseCompletion] {
        let cal = Calendar(identifier: .gregorian)
        return allCompletions.filter { cal.isDate($0.completedAt, inSameDayAs: selectedDate) }
    }
    
    private var isChallengeDoneForSelectedDate: Bool {
        let key = dateKey(selectedDate)
        guard let data = completedChallengesJSON.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else { return false }
        return dict[key] ?? false
    }
    
    private func dateKey(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    private func getSymptoms() -> [String: String] {
        guard let data = storedSymptomsJSON.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return [:] }
        return obj
    }
    
    private func saveSymptoms(_ dict: [String: String]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            storedSymptomsJSON = str
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 251/255, blue: 248/255).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    // Header
                    HStack {
                        Text(storedName.isEmpty ? "Journal" : "\(storedName)'s Journal")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar Card
                    VStack {
                        MonthGrid(selectedDate: $selectedDate, highlightColor: purpleHighlight)
                    }
                    .frame(maxWidth: .infinity)
                    .background(lightCardColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Main Date Text - FIXED ERROR HERE
                    HStack {
                        Text(selectedDate.formatted(.dateTime.day().month().year()))
                            .environment(\.calendar, Calendar(identifier: .gregorian))
                            .font(.title2.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    symptomSection
                        .padding(.horizontal, 20)
                    
                    agendaSection
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
        }
    }
}

// MARK: - Subview Sections
private extension CalendarView {
    var symptomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    if isLoggingSymptoms {
                        var dict = getSymptoms()
                        if symptomNotes.isEmpty { dict.removeValue(forKey: dateKey(selectedDate)) }
                        else { dict[dateKey(selectedDate)] = symptomNotes }
                        saveSymptoms(dict)
                        isLoggingSymptoms = false
                    } else {
                        symptomNotes = getSymptoms()[dateKey(selectedDate)] ?? ""
                        isLoggingSymptoms = true
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isLoggingSymptoms ? "checkmark.circle.fill" : "plus.circle.fill")
                    Text("Log your symptoms").bold()
                    Spacer()
                }
                .font(.title3)
                .foregroundStyle(.black)
            }
            
            if isLoggingSymptoms {
                TextEditor(text: $symptomNotes)
                    .frame(height: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.5)))
                    .foregroundStyle(.black)
            } else if let note = getSymptoms()[dateKey(selectedDate)], !note.isEmpty {
                Text(note)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.black)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.4)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(red: 233/255, green: 224/255, blue: 247/255))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var agendaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Log")
                .font(.title3.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.black)
            
            if completionsForSelectedDate.isEmpty && !isChallengeDoneForSelectedDate {
                Text("No activities recorded for this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                if isChallengeDoneForSelectedDate {
                    ForEach(["Daily Brain Challenge"], id: \.self) { title in
                        HStack(spacing: 15) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                Text("Completed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
                    }
                }
                
                ForEach(completionsForSelectedDate) { completion in
                    HStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.black)
                            .font(.title3)
                        
                        VStack(alignment: .leading) {
                            Text(completion.exerciseName)
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("\(completion.durationInMinutes) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lightCardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - MonthGrid
private struct MonthGrid: View {
    @Binding var selectedDate: Date
    var highlightColor: Color
    
    @State private var currentMonthAnchor: Date = {
        var cal = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = cal.component(.month, from: .now)
        components.day = 1
        return cal.date(from: components) ?? .now
    }()
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }
    
    private let weekdaySymbols = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 15), count: 7)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Button {
                    withAnimation {
                        let today = Date()
                        selectedDate = calendar.startOfDay(for: today)
                        currentMonthAnchor = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Today").font(.caption.bold())
                    }
                    .foregroundStyle(.black)
                    .padding(8)
                    .background(Capsule().fill(.white.opacity(0.5)))
                }
                
                Spacer()
                
                // Header Year Fixed to Gregorian
                Text(currentMonthAnchor.formatted(.dateTime.month(.wide).year()))
                    .environment(\.calendar, Calendar(identifier: .gregorian))
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.black)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { changeMonth(by: -1) }) { 
                        Image(systemName: "chevron.left").bold().foregroundStyle(.black)
                    }
                    Button(action: { changeMonth(by: 1) }) { 
                        Image(systemName: "chevron.right").bold().foregroundStyle(.black)
                    }
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.7))
                }
            }
            
            let days = generateDays()
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(days.indices, id: \.self) { index in
                    if let date = days[index] {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(width: 45, height: 45)
                            .background(calendar.isDate(date, inSameDayAs: selectedDate) ? highlightColor : Color.clear)
                            .clipShape(Circle())
                            .foregroundStyle(.black)
                            .onTapGesture {
                                withAnimation { selectedDate = calendar.startOfDay(for: date) }
                            }
                    } else {
                        Color.clear.frame(width: 45, height: 45)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
    }
    
    private func changeMonth(by value: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonthAnchor) {
                currentMonthAnchor = newDate
            }
        }
    }
    
    private func generateDays() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: currentMonthAnchor)
        guard let firstOfMonth = calendar.date(from: components),
              let monthRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

#Preview {
    CalendarView()
}

