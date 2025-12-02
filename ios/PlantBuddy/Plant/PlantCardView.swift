import SwiftUI

struct PlantCardView: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plant Image
            ZStack {
                if let imageUrl = plant.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.green)
                        .padding(20)
                }
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Plant Name
            Text(plant.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Next Water Date
            if let nextWater = plant.nextWaterDateParsed {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Water: \(formatDate(nextWater))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No schedule")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Care Level Badge
            if let careLevel = plant.careLevel {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text(careLevel.capitalized)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(careLevelColor(careLevel).opacity(0.2))
                .foregroundColor(careLevelColor(careLevel))
                .cornerRadius(4)
            }
            
            // Species
            if let species = plant.species {
                Text(species)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < Date() {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(days) day\(days == 1 ? "" : "s") overdue"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func careLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }
}

#Preview("Plant Card") {
    PlantCardView(plant: MockData.plants.first!)
}
