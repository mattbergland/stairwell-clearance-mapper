import Foundation

/// One obstacle on the route, in walking order.
struct Obstacle: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var note: String?
    var kind: ObstacleKind

    /// All measurements are stored in inches, regardless of display units.
    enum ObstacleKind: Codable, Hashable {
        case doorway(width: Double, height: Double)
        case straightStairs(width: Double, headroom: Double, rise: Double, run: Double)
        case turn90(widthIn: Double, widthOut: Double, ceiling: Double)
        case uTurn(widthIn: Double, landingDepth: Double, widthOut: Double, ceiling: Double)
    }

    /// The kind of obstacle, for grouping the form fields and picking a title.
    enum KindType: String, CaseIterable {
        case doorway, straightStairs, turn90, uTurn

        var title: String {
            switch self {
            case .doorway: "Doorway"
            case .straightStairs: "Straight stairs"
            case .turn90: "90° turn"
            case .uTurn: "U-turn landing"
            }
        }

        var explanation: String {
            switch self {
            case .doorway: "Any door or opening you walk through"
            case .straightStairs: "A run of steps with no turn"
            case .turn90: "A landing or hallway corner where you turn left or right"
            case .uTurn: "A landing where the stairs double back the other way"
            }
        }
    }

    var kindType: KindType {
        switch kind {
        case .doorway: .doorway
        case .straightStairs: .straightStairs
        case .turn90: .turn90
        case .uTurn: .uTurn
        }
    }
}
