import SwiftUI

struct LogActivityView: View {
    let plant: Plant
    let onActivityLogged: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var actionType: ActionType = .water
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum ActionType: String, CaseIterable {
        case water = "WATER"
        case fertilize = "FERTILIZE"
        case repotting = "REPOTTING"
        case prune = "PRUNE"
        case snooze = "SNOOZE"
        case skippedRain = "SKIPPED_RAIN"
        case photo = "PHOTO"
        case note = "NOTE"
        
        var displayName: String {
            switch self {
            case .water: return "Water"
            case .fertilize: return "Fertilize"
            case .repotting: return "Repotting"
            case .prune: return "Prune"
            case .snooze: return "Snooze"
            case .skippedRain: return "Skipped (Rain)"
            case .photo: return "Photo"
            case .note: return "Note"
            }
        }
        
        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .fertilize: return "leaf.fill"
            case .repotting: return "square.stack.3d.up.fill"
            case .prune: return "scissors"
            case .snooze: return "clock.fill"
            case .skippedRain: return "cloud.rain.fill"
            case .photo: return "photo.fill"
            case .note: return "note.text"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Type")) {
                    Picker("Type", selection: $actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        logActivity()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func logActivity() {
        isSubmitting = true
        
        guard let token = authManager.token else {
            errorMessage = "Not authenticated"
            showError = true
            isSubmitting = false
            return
        }
        
        PlantService.shared.performAction(
            plantId: plant.id,
            actionType: actionType.rawValue,
            notes: notes.isEmpty ? nil : notes,
            token: token
        ) { result in
            DispatchQueue.main.async {
                self.isSubmitting = false
                switch result {
                case .success(let response):
                    // Add to local activity log
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    let activity = ActivityLog(
                        id: Int.random(in: 1000...9999),
                        actionType: actionType.rawValue,
                        actionDate: formatter.string(from: Date()),
                        notes: notes.isEmpty ? nil : notes
                    )
                    
                    MockData.addActivity(plantId: plant.id, activity: activity)
                    self.onActivityLogged()
                    self.dismiss()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

