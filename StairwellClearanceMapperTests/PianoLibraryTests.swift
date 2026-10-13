@testable import StairwellClearanceMapper
import XCTest

final class PianoLibraryTests: XCTestCase {

    private func loadLibrary() throws -> [Piano] {
        guard let url = Bundle(for: Self.self).url(forResource: "PianoLibrary",
                                                   withExtension: "json")
                ?? Bundle.main.url(forResource: "PianoLibrary", withExtension: "json") else {
            // Fall back to the source-tree copy so the test doesn't depend on bundling.
            let source = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("StairwellClearanceMapper/Resources/PianoLibrary.json")
            return try JSONDecoder().decode([Piano].self, from: Data(contentsOf: source))
        }
        return try JSONDecoder().decode([Piano].self, from: Data(contentsOf: url))
    }

    func testLibraryDecodes() throws {
        let pianos = try loadLibrary()
        XCTAssertGreaterThanOrEqual(pianos.count, 20)
        XCTAssertEqual(Set(pianos.map(\.id)).count, pianos.count, "ids must be unique")
        for piano in pianos {
            XCTAssertTrue(piano.hasValidDimensions, "\(piano.name) has missing/zero dims")
            XCTAssertFalse(piano.name.isEmpty)
            XCTAssertGreaterThan(piano.weightLb, 0)
        }
    }

    func testSteinwayModelMIsPresent() throws {
        let pianos = try loadLibrary()
        let modelM = try XCTUnwrap(pianos.first { $0.id == "steinway-model-m" })
        XCTAssertEqual(modelM.category, .grand)
        XCTAssertEqual(modelM.length, 67)
        XCTAssertEqual(modelM.width, 56.5)
        XCTAssertEqual(modelM.caseThickness, 13.5)
    }
}
