import XCTest
@testable import AppCore

final class GamificationManagerTests: XCTestCase {
    func testAwardTaskCompletedAddsPoints() {
        var data = GamificationData()
        let manager = GamificationManager()
        manager.awardTaskCompleted(&data)
        XCTAssertEqual(data.totalPoints, 5)
    }

    func testAwardAllTasksCompletedAddsBonus() {
        var data = GamificationData()
        let manager = GamificationManager()
        manager.awardAllTasksCompleted(&data)
        XCTAssertEqual(data.totalPoints, 20)
    }
}
