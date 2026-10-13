import Foundation

/// Pure-Swift fit math. All values in inches. No SwiftUI.
enum ClearanceEngine {

    // MARK: - Verdicts

    static func verdict(clearance c: Double, safetyMargin m: Double) -> Verdict {
        if c >= m { return .fits }
        if c < 0 { return .wontFit }
        return .tight
    }

    // MARK: - Orientations

    /// Every carry orientation worth trying for this piano, dimensions padded.
    static func orientations(for piano: Piano, paddingPerSide p: Double) -> [CarryOrientation] {
        func pad(_ v: Double) -> Double { v + 2 * p }
        switch piano.category {
        case .upright, .pumpOrgan:
            let w = pad(piano.width ?? 0)
            let d = pad(piano.depth ?? 0)
            let h = pad(piano.height ?? 0)
            return [
                CarryOrientation(name: "Standing, end first", along: w, across: d, up: h),
                CarryOrientation(name: "On its back, end first", along: w, across: h, up: d),
                CarryOrientation(name: "On its back, top first", along: h, across: w, up: d),
                CarryOrientation(name: "On its end on a skid", along: h, across: d, up: w)
            ]
        case .grand, .squareGrand:
            let skid = 2.0
            let l = pad(piano.length ?? 0)
            let w = pad(piano.width ?? 0)
            let t = pad(piano.caseThickness ?? 0)
            return [
                CarryOrientation(name: "On its side on a skid", along: l, across: t, up: w + skid),
                CarryOrientation(name: "Stood on its tail end", along: w + skid, across: t, up: l)
            ]
        }
    }

    // MARK: - Stairs

    /// Headroom measured perpendicular to the stair slope.
    static func perpendicularHeadroom(headroom: Double, rise: Double, run: Double) -> Double {
        headroom * cos(atan(rise / run))
    }

    // MARK: - Turns

    /// Longest straight-ish line that can be tilted through a 90° corner
    /// between corridors of width `a` and `b`, carrying width `w` across.
    /// Returns nil when the carried width can't even fit the narrower corridor.
    static func lMax(a: Double, b: Double, w: Double) -> Double? {
        if w >= min(a, b) { return nil }
        var best = Double.greatestFiniteMagnitude
        var tenths = 5 // 0.5° to 89.5° in 0.1° steps
        while tenths <= 895 {
            let theta = Double(tenths) / 10 * .pi / 180
            let s = sin(theta)
            let c = cos(theta)
            let value = a / s + b / c - w / (s * c)
            if value < best { best = value }
            tenths += 1
        }
        return best
    }

    struct TurnResult {
        var clearance: Double
        var limitingFactor: LimitingFactor
        var tiltDegrees: Int
    }

    /// Best achievable clearance through a 90° turn, tilting up to 60°.
    static func turn(_ orientation: CarryOrientation, a: Double, b: Double, ceiling: Double) -> TurnResult {
        let narrow = min(a, b)
        guard let lMax = lMax(a: a, b: b, w: orientation.across) else {
            return TurnResult(clearance: narrow - orientation.across,
                              limitingFactor: .hallwayWidth,
                              tiltDegrees: 0)
        }
        var best = TurnResult(clearance: -.greatestFiniteMagnitude,
                              limitingFactor: .hallwayWidth,
                              tiltDegrees: 0)
        for phi in 0...60 {
            let radians = Double(phi) * .pi / 180
            let lh = orientation.along * cos(radians) + orientation.up * sin(radians)
            let v = orientation.along * sin(radians) + orientation.up * cos(radians)
            let candidates: [(Double, LimitingFactor)] = [
                (narrow - orientation.across, .hallwayWidth),
                (lMax - lh, .makingTurn),
                (ceiling - v, .ceiling)
            ]
            let (c, factor) = candidates.min { $0.0 < $1.0 }!
            if c > best.clearance {
                best = TurnResult(clearance: c, limitingFactor: factor, tiltDegrees: phi)
            }
        }
        return best
    }

    /// A U-turn landing is two 90° turns back to back; the worse one rules.
    static func uTurn(_ orientation: CarryOrientation, widthIn: Double,
                      landingDepth: Double, widthOut: Double,
                      ceiling: Double) -> TurnResult {
        let turn1 = turn(orientation, a: widthIn, b: landingDepth, ceiling: ceiling)
        let turn2 = turn(orientation, a: landingDepth, b: widthOut, ceiling: ceiling)
        return turn1.clearance <= turn2.clearance ? turn1 : turn2
    }

    // MARK: - Evaluation

    /// Evaluates one obstacle against every carry orientation and keeps the best.
    static func evaluate(_ obstacle: Obstacle, piano: Piano, settings: Settings) -> ObstacleResult {
        let orientations = orientations(for: piano, paddingPerSide: settings.paddingPerSide)
        var best = ObstacleResult(verdict: .wontFit,
                                clearance: -.greatestFiniteMagnitude,
                                limitingFactor: .doorWidth,
                                orientationName: "",
                                tiltDegrees: 0,
                                advice: [])
        for orientation in orientations {
            let candidate = evaluate(orientation: orientation, obstacle: obstacle)
            if candidate.clearance > best.clearance {
                best = candidate
            }
        }
        best.verdict = verdict(clearance: best.clearance, safetyMargin: settings.safetyMargin)
        if best.verdict == .wontFit {
            best.advice = advice(for: obstacle, piano: piano, result: best)
        }
        return best
    }

    private static func evaluate(orientation: CarryOrientation,
                                 obstacle: Obstacle) -> ObstacleResult {
        var clearance: Double
        var limiting: LimitingFactor
        var tilt = 0
        switch obstacle.kind {
        case let .doorway(width, height):
            let widthSlack = width - orientation.across
            let heightSlack = height - orientation.up
            if widthSlack <= heightSlack {
                clearance = widthSlack
                limiting = .doorWidth
            } else {
                clearance = heightSlack
                limiting = .doorHeight
            }
        case let .straightStairs(width, headroom, rise, run):
            let perp = perpendicularHeadroom(headroom: headroom, rise: rise, run: run)
            let widthSlack = width - orientation.across
            let headSlack = perp - orientation.up
            if widthSlack <= headSlack {
                clearance = widthSlack
                limiting = .stairWidth
            } else {
                clearance = headSlack
                limiting = .headroom
            }
        case let .turn90(widthIn, widthOut, ceiling):
            let result = turn(orientation, a: widthIn, b: widthOut, ceiling: ceiling)
            clearance = result.clearance
            limiting = result.limitingFactor
            tilt = result.tiltDegrees
        case let .uTurn(widthIn, landingDepth, widthOut, ceiling):
            let worse = uTurn(orientation, widthIn: widthIn,
                              landingDepth: landingDepth,
                              widthOut: widthOut, ceiling: ceiling)
            clearance = worse.clearance
            limiting = worse.limitingFactor
            tilt = worse.tiltDegrees
        }
        return ObstacleResult(verdict: .wontFit,
                              clearance: clearance,
                              limitingFactor: limiting,
                              orientationName: orientation.name,
                              tiltDegrees: tilt,
                              advice: [])
    }

    /// Friendly suggestions, only for obstacles that won't fit.
    private static func advice(for obstacle: Obstacle, piano: Piano, result: ObstacleResult) -> [String] {
        var tips: [String] = []
        var covered = false
        switch obstacle.kind {
        case .doorway:
            if result.clearance >= -2 {
                tips.append("Take the door off its hinges and pull the stop molding — usually gains about 1–1½ in.")
                covered = true
            }
        case .straightStairs:
            if result.limitingFactor == .stairWidth {
                tips.append("Remove the handrail (often gains 3–4 in).")
                covered = true
            }
        case .turn90, .uTurn:
            tips.append("Try lifting the leading end higher, or plan a hoist through a window or balcony.")
            covered = true
        }
        if piano.category == .grand || piano.category == .squareGrand {
            tips.append("Make sure the legs, lyre, and lid are off.")
        }
        if !covered {
            tips.append("Consider a hoist or a different entrance.")
        }
        return tips
    }

    // MARK: - Route

    static func evaluateRoute(obstacles: [Obstacle], piano: Piano, settings: Settings) -> RouteResult {
        let results = obstacles.map { evaluate($0, piano: piano, settings: settings) }
        let summary: RouteSummary
        if results.contains(where: { $0.verdict == .wontFit }) {
            summary = .needsDifferentPlan
        } else if results.contains(where: { $0.verdict == .tight }) {
            summary = .goWithCare
        } else {
            summary = .go
        }
        return RouteResult(summary: summary, results: results)
    }

    /// Rounded tilt tip: "Lift the leading end about N°", N rounded to the nearest 5 (min 5).
    static func tiltTip(tiltDegrees: Int) -> String? {
        guard tiltDegrees > 0 else { return nil }
        let n = max(5, Int((Double(tiltDegrees) / 5).rounded()) * 5)
        return "Lift the leading end about \(n)°"
    }
}
