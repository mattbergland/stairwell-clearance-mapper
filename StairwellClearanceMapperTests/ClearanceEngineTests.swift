@testable import StairwellClearanceMapper
import XCTest

final class ClearanceEngineTests: XCTestCase {

    // MARK: - Helpers

    private func piano(id: String = "test-grand") -> Piano {
        // Steinway Model M: length 67, width 56.5, case thickness 13.5
        Piano(id: id, name: "Steinway Model M", era: "1911–", category: .grand,
              weightLb: 560, width: 56.5, length: 67, caseThickness: 13.5)
    }

    private var noPadding: Settings {
        Settings(units: .inches, paddingPerSide: 0, safetyMargin: 1)
    }

    // MARK: - 1. lMax

    func testLMax() {
        XCTAssertEqual(ClearanceEngine.lMax(a: 36, b: 36, w: 0)!, 101.82, accuracy: 0.2)
        XCTAssertEqual(ClearanceEngine.lMax(a: 36, b: 36, w: 26)!, 49.82, accuracy: 0.2)
        XCTAssertNil(ClearanceEngine.lMax(a: 36, b: 36, w: 36))
        XCTAssertNil(ClearanceEngine.lMax(a: 36, b: 30, w: 31))
    }

    // MARK: - 2. Perpendicular headroom

    func testPerpendicularHeadroom() {
        XCTAssertEqual(ClearanceEngine.perpendicularHeadroom(headroom: 80, rise: 7.5, run: 10),
                       64.0, accuracy: 0.01)
    }

    // MARK: - 3. Doorway with Model M

    func testDoorwayModelM() {
        let obstacle = Obstacle(name: "Front door", kind: .doorway(width: 36, height: 80))
        let result = ClearanceEngine.evaluate(obstacle, piano: piano(), settings: noPadding)
        XCTAssertEqual(result.orientationName, "On its side on a skid")
        XCTAssertEqual(result.clearance, 21.5, accuracy: 0.001)
        XCTAssertEqual(result.limitingFactor, .doorHeight)
        XCTAssertEqual(result.verdict, .fits)
    }

    // MARK: - 4. Verdict thresholds

    func testVerdictThresholds() {
        XCTAssertEqual(ClearanceEngine.verdict(clearance: 1.0, safetyMargin: 1), .fits)
        XCTAssertEqual(ClearanceEngine.verdict(clearance: 0.999, safetyMargin: 1), .tight)
        XCTAssertEqual(ClearanceEngine.verdict(clearance: 0, safetyMargin: 1), .tight)
        XCTAssertEqual(ClearanceEngine.verdict(clearance: -0.01, safetyMargin: 1), .wontFit)
    }

    // MARK: - 5. 90° turn

    private var syntheticOrientation: CarryOrientation {
        CarryOrientation(name: "test", along: 80, across: 20, up: 20)
    }

    func testTurn90FlatFails() {
        // Ceiling so low that tilting never helps: the best angle stays flat.
        let result = ClearanceEngine.turn(syntheticOrientation, a: 36, b: 36, ceiling: 15)
        XCTAssertEqual(result.clearance, -18.18, accuracy: 0.2)
        XCTAssertEqual(result.tiltDegrees, 0)
    }

    func testTurn90HighCeilingFits() {
        let result = ClearanceEngine.turn(syntheticOrientation, a: 36, b: 36, ceiling: 120)
        XCTAssertEqual(result.clearance, 4.5, accuracy: 0.2)
        XCTAssertEqual(result.tiltDegrees, 60)
    }

    func testTurn90LowCeilingFails() {
        let result = ClearanceEngine.turn(syntheticOrientation, a: 36, b: 36, ceiling: 70)
        XCTAssertEqual(result.clearance, -4.76, accuracy: 0.2)
    }

    // MARK: - 6. U-turn

    func testUTurn() {
        let turn1 = ClearanceEngine.turn(syntheticOrientation, a: 36, b: 40, ceiling: 120)
        let turn2 = ClearanceEngine.turn(syntheticOrientation, a: 40, b: 30, ceiling: 120)
        XCTAssertEqual(turn1.clearance, 10.06, accuracy: 0.2)
        XCTAssertEqual(turn2.clearance, 0.93, accuracy: 0.2)

        let uResult = ClearanceEngine.uTurn(syntheticOrientation, widthIn: 36,
                                            landingDepth: 40, widthOut: 30,
                                            ceiling: 120)
        XCTAssertEqual(uResult.clearance, min(turn1.clearance, turn2.clearance), accuracy: 0.2)
        XCTAssertEqual(uResult.clearance, 0.93, accuracy: 0.2)
    }

    // MARK: - 7. Best orientation selection

    func testBestOrientationPicked() {
        let studio = Piano(id: "studio", name: "Studio upright (generic)", era: "any",
                           category: .upright, weightLb: 500,
                           width: 58, depth: 25, height: 45)
        let lowOpening = Obstacle(name: "Low door", kind: .doorway(width: 60, height: 40))
        let result = ClearanceEngine.evaluate(lowOpening, piano: studio, settings: noPadding)
        XCTAssertEqual(result.orientationName, "On its back, end first")
        XCTAssertEqual(result.clearance, 15, accuracy: 0.001)
        XCTAssertEqual(result.verdict, .fits)
    }

    // MARK: - 9. Sample job

    func testSampleJob() {
        let state = AppState() // default settings: padding 0.5, margin 1
        state.loadSampleJob()
        let piano = state.route.piano!
        let results = state.route.obstacles.map {
            ClearanceEngine.evaluate($0, piano: piano, settings: state.route.settings)
        }
        XCTAssertEqual(results.count, 6)
        XCTAssertEqual(results[0].verdict, .fits)   // Front door
        XCTAssertEqual(results[1].verdict, .fits)   // Vestibule door
        XCTAssertEqual(results[2].verdict, .tight)  // Main stairs
        XCTAssertEqual(results[2].clearance, 0.29, accuracy: 0.2)
        XCTAssertEqual(results[3].verdict, .fits)   // Landing turn
        XCTAssertEqual(results[3].clearance, 4.81, accuracy: 0.2)
        XCTAssertEqual(results[3].orientationName, "Stood on its tail end")
        XCTAssertEqual(results[4].verdict, .wontFit) // Upper stairs
        XCTAssertEqual(results[4].clearance, -2.7, accuracy: 0.2)
        XCTAssertEqual(results[5].verdict, .fits)   // Parlor door

        let route = ClearanceEngine.evaluateRoute(obstacles: state.route.obstacles,
                                                  piano: piano,
                                                  settings: state.route.settings)
        XCTAssertEqual(route.summary, .needsDifferentPlan)
    }
}
