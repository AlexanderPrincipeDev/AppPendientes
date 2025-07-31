import Foundation

struct GamificationData: Codable {
    var totalPoints: Int = 0
    var level: Int = 1
    var streak: Int = 0
    var maxStreak: Int = 0
    var lastTaskDate: String?
    var achievements: [Achievement] = Achievement.defaultAchievements

    mutating func addPoints(_ pointsToAdd: Int) {
        totalPoints += pointsToAdd
        updateLevel()
    }

    private mutating func updateLevel() {
        let newLevel = (totalPoints / 100) + 1
        if newLevel > level {
            level = newLevel
        }
    }
}

struct Achievement: Codable {
    var title: String
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var points: Int

    static var defaultAchievements: [Achievement] {
        return [
            Achievement(title: "Primera Tarea", points: 10),
            Achievement(title: "Racha de 3", points: 15),
            Achievement(title: "Racha de 7", points: 25),
            Achievement(title: "Constante", points: 50),
            Achievement(title: "Perfeccionista", points: 100),
            Achievement(title: "Productivo", points: 20),
            Achievement(title: "Centenario", points: 30),
            Achievement(title: "Milionario", points: 50)
        ]
    }
}

final class GamificationManager {
    func awardTaskCompleted(_ data: inout GamificationData) {
        data.addPoints(5)
    }

    func awardAllTasksCompleted(_ data: inout GamificationData) {
        data.addPoints(20)
    }
}
