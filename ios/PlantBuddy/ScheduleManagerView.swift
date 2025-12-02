import SwiftUI

struct ScheduleManagerView: View {
    let plant: Plant
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var schedules: [Schedule] = []
    @State private var showAddSchedule = false
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Schedules")) {
                    if schedules.isEmpty {
                        Text("No schedules set. Add one below.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    } else {
                        ForEach(schedules, id: \.id) { schedule in
                            ScheduleRowView(schedule: schedule, onDelete: {
                                deleteSchedule(schedule)
                            })
                        }
                    }
                }
                
                Section {
                    Button(action: { showAddSchedule = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Schedule")
                        }
                    }
                }
            }
            .navigationTitle("Manage Schedules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddSchedule) {
                AddScheduleView(plant: plant, onScheduleAdded: { newSchedule in
                    saveSchedule(schedule: newSchedule)
                })
            }
            .onAppear {
                loadSchedules()
            }
        }
    }
    
    private func loadSchedules() {
        if let plantSchedules = plant.schedules {
            schedules = plantSchedules.filter { $0.isActive }
        }
    }
    
    private func deleteSchedule(_ schedule: Schedule) {
        guard let token = authManager.token else {
            schedules.removeAll { $0.id == schedule.id }
            return
        }
        
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/\(plant.id)/schedules/\(schedule.id)/") else {
            schedules.removeAll { $0.id == schedule.id }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    schedules.removeAll { $0.id == schedule.id }
                } else {
                    // Still remove from local list even if API fails
                    schedules.removeAll { $0.id == schedule.id }
                }
            }
        }.resume()
    }
    
    private func saveSchedule(schedule: Schedule) {
        guard let token = authManager.token else { return }
        
        isSubmitting = true
        
        let baseURL = "http://192.168.4.23:8000/api"
        guard let url = URL(string: "\(baseURL)/plants/\(plant.id)/schedules/") else {
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "task_type": schedule.taskType,
            "frequency_days": schedule.frequencyDays
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    // Add to local list
                    schedules.append(schedule)
                }
            }
        }.resume()
    }
}

struct ScheduleRowView: View {
    let schedule: Schedule
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.taskType.capitalized)
                    .font(.headline)
                
                Text("Every \(schedule.frequencyDays) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Next: \(formatDate(schedule.nextDueDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
    }
}

struct AddScheduleView: View {
    let plant: Plant
    let onScheduleAdded: (Schedule) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var taskType: TaskType = .water
    @State private var frequencyDays = 7
    
    enum TaskType: String, CaseIterable {
        case water = "WATER"
        case fertilize = "FERTILIZE"
        case repotting = "REPOTTING"
        case prune = "PRUNE"
        
        var displayName: String {
            switch self {
            case .water: return "Water"
            case .fertilize: return "Fertilize"
            case .repotting: return "Repotting"
            case .prune: return "Prune"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Type")) {
                    Picker("Type", selection: $taskType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Frequency")) {
                    HStack {
                        Text("Every")
                        Spacer()
                        Stepper("\(frequencyDays) days", value: $frequencyDays, in: 1...90)
                    }
                }
            }
            .navigationTitle("Add Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let nextDueDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: Date()) ?? Date()
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
                        
                        let newSchedule = Schedule(
                            id: Int.random(in: 1000...9999),
                            taskType: taskType.rawValue,
                            frequencyDays: frequencyDays,
                            nextDueDate: formatter.string(from: nextDueDate),
                            isActive: true
                        )
                        onScheduleAdded(newSchedule)
                        dismiss()
                    }
                }
            }
        }
    }
}

