import Foundation

enum MeasurementUnits: String, Codable, CaseIterable {
    case inches
    case centimeters

    var displayName: String {
        switch self {
        case .inches: "Inches"
        case .centimeters: "Centimeters"
        }
    }
}

struct Settings: Codable, Hashable {
    var units: MeasurementUnits = .inches
    /// Blanket / board padding added to each side of the piano, in inches.
    var paddingPerSide: Double = 0.5
    /// Extra breathing room needed before a fit is called comfortable, in inches.
    var safetyMargin: Double = 1.0
}
