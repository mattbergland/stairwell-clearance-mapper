import SwiftUI

/// The verdict screen: one banner for the whole route, one card per obstacle.
struct FitCheckView: View {
    @Environment(AppState.self) private var state

    private var routeResult: RouteResult? {
        guard let piano = state.route.piano else { return nil }
        guard !state.route.obstacles.isEmpty else { return nil }
        return ClearanceEngine.evaluateRoute(obstacles: state.route.obstacles,
                                             piano: piano,
                                             settings: state.route.settings)
    }

    var body: some View {
        Group {
            if let routeResult {
                resultList(routeResult)
            } else {
                ContentUnavailableView {
                    Label("Nothing to check yet", systemImage: "checkmark.shield")
                } description: {
                    if state.route.piano == nil {
                        Text("Pick a piano on the Pianos tab first.")
                    } else {
                        Text("Add at least one obstacle on the Route tab.")
                    }
                }
            }
        }
        .navigationTitle("Fit Check")
    }

    private func resultList(_ routeResult: RouteResult) -> some View {
        List {
            Section {
                SummaryBanner(summary: routeResult.summary)
            }
            ForEach(Array(zip(state.route.obstacles, routeResult.results)), id: \.0.id) { obstacle, result in
                ResultCard(obstacle: obstacle, result: result, units: state.route.settings.units)
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }
}

struct SummaryBanner: View {
    let summary: RouteSummary

    private var style: (icon: String, color: Color) {
        switch summary {
        case .go: ("checkmark.circle.fill", .green)
        case .goWithCare: ("exclamationmark.triangle.fill", .orange)
        case .needsDifferentPlan: ("xmark.octagon.fill", .red)
        }
    }

    var body: some View {
        Label(summary.rawValue, systemImage: style.icon)
            .font(.title2.bold())
            .foregroundStyle(style.color)
            .frame(maxWidth: .infinity, minHeight: 60)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Route summary: \(summary.rawValue)")
            .accessibilityIdentifier("routeSummary")
    }
}

struct ResultCard: View {
    let obstacle: Obstacle
    let result: ObstacleResult
    let units: MeasurementUnits

    private var style: (icon: String, color: Color) {
        switch result.verdict {
        case .fits: ("checkmark.circle.fill", .green)
        case .tight: ("exclamationmark.triangle.fill", .orange)
        case .wontFit: ("xmark.octagon.fill", .red)
        }
    }

    private var clearanceText: String {
        let amount = MeasurementFormatting.clearance(result.clearance, units: units)
        return result.clearance >= 0 ? "\(amount) to spare" : "\(amount) short"
    }

    private var accessibilityDescription: String {
        let amount = MeasurementFormatting.spokenClearance(result.clearance, units: units)
        let spare = result.clearance >= 0 ? "\(amount) to spare" : "\(amount) short"
        var text = "\(obstacle.name): \(result.verdict.rawValue), \(spare), carry \(result.orientationName.lowercased())"
        if let tip = ClearanceEngine.tiltTip(tiltDegrees: result.tiltDegrees) {
            text += ". \(tip)"
        }
        return text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(obstacle.name)
                .font(.headline)
            HStack {
                Label(result.verdict.rawValue, systemImage: style.icon)
                    .font(.headline)
                    .foregroundStyle(style.color)
                Spacer()
                Text(clearanceText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Best way to carry: \(result.orientationName)")
                .font(.subheadline)
            Text("Tightest spot: \(result.limitingFactor.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let tip = ClearanceEngine.tiltTip(tiltDegrees: result.tiltDegrees) {
                Label(tip, systemImage: "arrow.up.forward")
                    .font(.subheadline)
            }
            ForEach(result.advice, id: \.self) { tip in
                Label(tip, systemImage: "lightbulb")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityIdentifier("result.\(obstacle.name)")
    }
}
