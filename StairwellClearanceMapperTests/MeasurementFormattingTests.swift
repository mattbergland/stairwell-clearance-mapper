@testable import StairwellClearanceMapper
import XCTest

final class MeasurementFormattingTests: XCTestCase {

    func testFeetAndInches() {
        XCTAssertEqual(MeasurementFormatting.dimension(67, units: .inches), "5′7″")
        XCTAssertEqual(MeasurementFormatting.dimension(56.5, units: .inches), "56½″")
        XCTAssertEqual(MeasurementFormatting.dimension(36.25, units: .inches), "36¼″")
        XCTAssertEqual(MeasurementFormatting.dimension(80, units: .inches), "6′8″")
    }

    func testCentimeters() {
        XCTAssertEqual(MeasurementFormatting.dimension(67, units: .centimeters), "170 cm")
        XCTAssertEqual(MeasurementFormatting.dimension(56.5, units: .centimeters), "144 cm")
        XCTAssertEqual(MeasurementFormatting.dimensionPair(67, 56.5, units: .centimeters),
                       "170 × 144 cm")
    }

    func testClearance() {
        XCTAssertEqual(MeasurementFormatting.clearance(20.5, units: .inches), "20.5 in")
        XCTAssertEqual(MeasurementFormatting.clearance(4, units: .inches), "4 in")
        XCTAssertEqual(MeasurementFormatting.clearance(-2.7, units: .inches), "2.7 in")
        XCTAssertEqual(MeasurementFormatting.clearance(10, units: .centimeters), "25 cm")
    }
}
