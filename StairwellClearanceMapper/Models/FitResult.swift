import Foundation

enum Verdict: String, Codable {
    case fits = "Fits"
    case tight = "Tight"
    case wontFit = "Won't fit"
}

enum LimitingFactor: String, Codable {
    case doorWidth = "door width"
    case doorHeight = "door height"
    case stairWidth = "stair width"
    case headroom
    case hallwayWidth = "hallway width"
    case makingTurn = "making the turn"
    case ceiling = "ceiling at the turn"
}

/// A way to carry the piano: name plus the padded dimensions that run
/// along the path, across it, and straight up.
struct CarryOrientation: Hashable {
    var name: String
    var along: Double
    var across: Double
    var up: Double
}

struct ObstacleResult: Hashable {
    var verdict: Verdict
    var clearance: Double
    var limitingFactor: LimitingFactor
    var orientationName: String
    var tiltDegrees: Int
    var advice: [String]
}

enum RouteSummary: String {
    case go = "Go"
    case goWithCare = "Go with care"
    case needsDifferentPlan = "Needs a different plan"
}

struct RouteResult {
    var summary: RouteSummary
    var results: [ObstacleResult]
}
