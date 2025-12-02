import Foundation

struct MockData {
    static let plants: [Plant] = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let now = Date()
        
        let nextWater1 = Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now
        let nextWater2 = now
        
        return [
            Plant(
                id: 1,
                name: "Monstera",
                species: "Monstera Deliciosa",
                perenualId: nil,
                careLevel: "easy",
                imageUrl: nil,
                careTips: "Water when top inch of soil is dry",
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 1,
                        taskType: "WATER",
                        frequencyDays: 7,
                        nextDueDate: formatter.string(from: nextWater1),
                        isActive: true
                    )
                ],
                photos: nil,
                coverImageUrl: nil,
                nextWaterDate: formatter.string(from: nextWater1)
            ),
            Plant(
                id: 2,
                name: "Snake Plant",
                species: "Sansevieria",
                perenualId: nil,
                careLevel: "easy",
                imageUrl: nil,
                careTips: "Very low maintenance",
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 2,
                        taskType: "WATER",
                        frequencyDays: 14,
                        nextDueDate: formatter.string(from: nextWater2),
                        isActive: true
                    )
                ],
                photos: nil,
                coverImageUrl: nil,
                nextWaterDate: formatter.string(from: nextWater2)
            ),
            Plant(
                id: 3,
                name: "Pothos",
                species: "Epipremnum Aureum",
                perenualId: 300,
                careLevel: "easy",
                imageUrl: nil,
                careTips: nil,
                isDead: false,
                createdAt: formatter.string(from: now),
                updatedAt: formatter.string(from: now),
                schedules: [
                    Schedule(
                        id: 3,
                        taskType: "FERTILIZE",
                        frequencyDays: 30,
                        nextDueDate: formatter.string(from: Calendar.current.date(byAdding: .day, value: 15, to: now) ?? now),
                        isActive: true
                    )
                ],
                photos: nil,
                coverImageUrl: nil,
                nextWaterDate: nil
            )
        ]
    }()
    
    static let tasks: [Task] = [
        Task(
            id: 1,
            plantId: 1,
            plantName: "Monstera",
            taskType: "WATER",
            dueDate: ISO8601DateFormatter().string(from: Date()),
            frequencyDays: 7,
            scheduleId: 1,
            isOverdue: false
        ),
        Task(
            id: 2,
            plantId: 2,
            plantName: "Snake Plant",
            taskType: "WATER",
            dueDate: ISO8601DateFormatter().string(from: Date()),
            frequencyDays: 14,
            scheduleId: 2,
            isOverdue: false
        )
    ]
    
    // Activity logs storage
    private static var activityLogs: [Int: [ActivityLog]] = [:]
    
    static func getActivitiesForPlant(plantId: Int) -> [ActivityLog] {
        return activityLogs[plantId] ?? []
    }
    
    static func addActivity(plantId: Int, activity: ActivityLog) {
        if activityLogs[plantId] == nil {
            activityLogs[plantId] = []
        }
        activityLogs[plantId]?.insert(activity, at: 0) // Add to beginning
    }
}

