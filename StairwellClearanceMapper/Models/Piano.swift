import Foundation

enum PianoCategory: String, Codable, CaseIterable {
    case upright
    case grand
    case squareGrand
    case pumpOrgan

    var displayName: String {
        switch self {
        case .upright: "Upright"
        case .grand: "Grand"
        case .squareGrand: "Square grand"
        case .pumpOrgan: "Pump organ"
        }
    }
}

/// A piano in the built-in library, or a custom size entered by the user.
///
/// Uprights and pump organs use `width` (left-to-right), `depth` (front-to-back)
/// and `height`. Grands and square grands use `length` (keyboard to tail),
/// `width`, and `caseThickness` (the case depth with legs, lyre and lid off).
/// For square grands, `width` is the front-to-back depth — the dimension that
/// ends up vertical when the piano rides on its side.
struct Piano: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var era: String
    var category: PianoCategory
    var weightLb: Double

    // Upright / pump organ dimensions (inches)
    var width: Double?
    var depth: Double?
    var height: Double?

    // Grand / square grand dimensions (inches)
    var length: Double?
    var caseThickness: Double?

    var isCustom: Bool { id.hasPrefix("custom-") }

    /// Crew size rule of thumb: one person per ~150 lb, at least two.
    var crewSize: Int {
        max(2, Int(ceil(weightLb / 150.0)))
    }

    /// Validates that the dimensions required for the category are present and positive.
    var hasValidDimensions: Bool {
        switch category {
        case .upright, .pumpOrgan:
            return [width, depth, height].allSatisfy { ($0 ?? 0) > 0 }
        case .grand, .squareGrand:
            return [length, width, caseThickness].allSatisfy { ($0 ?? 0) > 0 }
        }
    }

    /// Names of the dimensions this category uses, in plain words.
    var dimensionLabels: [(label: String, value: Double)] {
        switch category {
        case .upright, .pumpOrgan:
            return [
                ("Width (left to right, as it sits)", width ?? 0),
                ("Depth (front to back)", depth ?? 0),
                ("Height", height ?? 0)
            ]
        case .grand, .squareGrand:
            return [
                ("Length (keyboard to tail)", length ?? 0),
                ("Width", width ?? 0),
                ("Case thickness (legs, lyre & lid off)", caseThickness ?? 0)
            ]
        }
    }
}
