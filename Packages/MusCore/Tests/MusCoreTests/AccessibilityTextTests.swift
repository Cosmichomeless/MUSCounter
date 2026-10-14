import XCTest
@testable import MusCore

final class AccessibilityTextTests: XCTestCase {
    func testPointsPluralization() {
        XCTAssertEqual(AccessibilityText.points(0), "0 tantos")
        XCTAssertEqual(AccessibilityText.points(1), "1 tanto")
        XCTAssertEqual(AccessibilityText.points(12), "12 tantos")
    }

    func testTeamValueDescribesProgressWithoutColor() {
        let value = AccessibilityText.teamValue(score: 12, goal: 40, vacas: 0, vacasToWin: 1, isLeading: false, isWinner: false)
        XCTAssertEqual(value, "12 tantos de 40")
    }

    func testTeamValueIncludesVacasOnlyWhenTheyMatter() {
        let withVacas = AccessibilityText.teamValue(score: 5, goal: 30, vacas: 1, vacasToWin: 3, isLeading: false, isWinner: false)
        XCTAssertEqual(withVacas, "5 tantos de 30, vacas 1 de 3")
        let single = AccessibilityText.teamValue(score: 5, goal: 30, vacas: 0, vacasToWin: 1, isLeading: false, isWinner: false)
        XCTAssertFalse(single.contains("vacas"))
    }

    func testTeamValueSaysWhoIsLeadingOrWon() {
        let leading = AccessibilityText.teamValue(score: 20, goal: 40, vacas: 0, vacasToWin: 1, isLeading: true, isWinner: false)
        XCTAssertTrue(leading.hasSuffix("va por delante"))
        let winner = AccessibilityText.teamValue(score: 40, goal: 40, vacas: 1, vacasToWin: 1, isLeading: false, isWinner: true)
        XCTAssertTrue(winner.hasSuffix("ha ganado la partida"))
    }

    func testScoreboardAnnouncement() {
        let names = PerTeam("Los Amigos", "La Peña")
        XCTAssertEqual(AccessibilityText.scoreboard(names: names, score: PerTeam(7, 3)), "Los Amigos 7, La Peña 3")
        XCTAssertEqual(AccessibilityText.scoreboard(names: names, score: PerTeam(4, 4)), "Empate a 4 tantos: Los Amigos y La Peña")
    }

    func testVictoryAnnouncementMentionsReason() {
        XCTAssertEqual(AccessibilityText.victory(winner: "La Peña", reason: .ordago), "¡Victoria de La Peña! Por órdago.")
        XCTAssertEqual(AccessibilityText.victory(winner: "La Peña", reason: .targetReached), "¡Victoria de La Peña! Objetivo alcanzado.")
    }
}
