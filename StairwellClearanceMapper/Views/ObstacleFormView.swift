import SwiftUI

/// Add or edit one obstacle. Every measurement has a "what to measure" hint
/// and inline validation; Save stays disabled until everything is sane.
struct ObstacleFormView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let kindType: Obstacle.KindType
    let existing: Obstacle?

    @State private var name: String
    @State private var note: String
    @State private var fields: [String: MeasurementDraft]

    init(kindType: Obstacle.KindType, existing: Obstacle?) {
        self.kindType = kindType
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _note = State(initialValue: existing?.note ?? "")
        _fields = State(initialValue: ObstacleFormView.drafts(for: kindType, existing: existing))
    }

    private static func drafts(for kind: Obstacle.KindType,
                               existing: Obstacle?) -> [String: MeasurementDraft] {
        func d(_ v: Double) -> MeasurementDraft { MeasurementDraft(inches: v) }
        switch existing?.kind {
        case let .doorway(w, h)?:
            return ["width": d(w), "height": d(h)]
        case let .straightStairs(w, head, rise, run)?:
            return ["width": d(w), "headroom": d(head), "rise": d(rise), "run": d(run)]
        case let .turn90(a, b, ceiling)?:
            return ["widthIn": d(a), "widthOut": d(b), "ceiling": d(ceiling)]
        case let .uTurn(a, landing, b, ceiling)?:
            return ["widthIn": d(a), "landingDepth": d(landing),
                    "widthOut": d(b), "ceiling": d(ceiling)]
        case nil:
            switch kind {
            case .doorway:
                return ["width": MeasurementDraft(), "height": MeasurementDraft()]
            case .straightStairs:
                return ["width": MeasurementDraft(), "headroom": MeasurementDraft(),
                        "rise": MeasurementDraft(inches: 7.5), "run": MeasurementDraft(inches: 10)]
            case .turn90:
                return ["widthIn": MeasurementDraft(), "widthOut": MeasurementDraft(),
                        "ceiling": MeasurementDraft()]
            case .uTurn:
                return ["widthIn": MeasurementDraft(), "landingDepth": MeasurementDraft(),
                        "widthOut": MeasurementDraft(), "ceiling": MeasurementDraft()]
            }
        }
    }

    private var units: MeasurementUnits { state.route.settings.units }

    private struct FieldSpec {
        let key: String
        let label: String
        let hint: String
    }

    private var specs: [FieldSpec] {
        switch kindType {
        case .doorway:
            return [
                FieldSpec(key: "width", label: "Opening width",
                          hint: "The narrowest part of the doorway — usually door stop to door stop, or door edge to stop."),
                FieldSpec(key: "height", label: "Opening height",
                          hint: "Floor to the top of the opening. Check for a low header or light fixture.")
            ]
        case .straightStairs:
            return [
                FieldSpec(key: "width", label: "Stair width",
                          hint: "Wall to wall, or wall to handrail — whichever is narrower. Measure at handrail height too."),
                FieldSpec(key: "headroom", label: "Headroom",
                          hint: "From the front edge of a step straight up to the ceiling above it — measure the lowest spot."),
                FieldSpec(key: "rise", label: "Step rise",
                          hint: "The height of one step. 7½ in is typical."),
                FieldSpec(key: "run", label: "Step run",
                          hint: "The depth of one step, front edge to front edge. 10 in is typical.")
            ]
        case .turn90:
            return [
                FieldSpec(key: "widthIn", label: "Hallway width before the turn",
                          hint: "Wall to wall on the way in."),
                FieldSpec(key: "widthOut", label: "Hallway width after the turn",
                          hint: "Wall to wall on the way out."),
                FieldSpec(key: "ceiling", label: "Ceiling height at the turn",
                          hint: "How high you can lift the piano's end while turning. Watch for lights.")
            ]
        case .uTurn:
            return [
                FieldSpec(key: "widthIn", label: "Stair width before the landing",
                          hint: "Wall to wall, or wall to handrail — whichever is narrower."),
                FieldSpec(key: "landingDepth", label: "Landing depth",
                          hint: "From the last step to the wall at the back of the landing."),
                FieldSpec(key: "widthOut", label: "Stair width after the landing",
                          hint: "Wall to wall, or wall to handrail — whichever is narrower."),
                FieldSpec(key: "ceiling", label: "Ceiling height over the landing",
                          hint: "How high you can lift the piano's end while turning it around.")
            ]
        }
    }

    private var allValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && specs.allSatisfy { fields[$0.key]?.isValid(units: units) == true }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField(kindType.title, text: $name)
                    .accessibilityIdentifier("obstacleName")
            }
            Section("Note (optional)") {
                TextField("e.g. “rail comes off with 3 screws”", text: $note)
                    .accessibilityIdentifier("obstacleNote")
            }
            Section("Measurements") {
                ForEach(specs, id: \.key) { spec in
                    if let draft = fields[spec.key] {
                        MeasurementField(label: spec.label,
                                         hint: spec.hint,
                                         draft: draft,
                                         units: units,
                                         fieldID: "field.\(spec.key)")
                    }
                }
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .navigationTitle(existing == nil ? "Add \(kindType.title.lowercased())"
                                        : "Edit \(kindType.title.lowercased())")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!allValid)
                    .accessibilityIdentifier("saveObstacle")
            }
        }
        .onAppear {
            if name.isEmpty && existing == nil {
                let count = state.route.obstacles.filter { $0.kindType == kindType }.count
                name = "\(kindType.title) \(count + 1)"
            }
        }
    }

    private func save() {
        func v(_ key: String) -> Double {
            fields[key]?.inches(units: units) ?? 0
        }
        let kind: Obstacle.ObstacleKind
        switch kindType {
        case .doorway:
            kind = .doorway(width: v("width"), height: v("height"))
        case .straightStairs:
            kind = .straightStairs(width: v("width"), headroom: v("headroom"),
                                   rise: v("rise"), run: v("run"))
        case .turn90:
            kind = .turn90(widthIn: v("widthIn"), widthOut: v("widthOut"),
                           ceiling: v("ceiling"))
        case .uTurn:
            kind = .uTurn(widthIn: v("widthIn"), landingDepth: v("landingDepth"),
                          widthOut: v("widthOut"), ceiling: v("ceiling"))
        }
        var obstacle = existing ?? Obstacle(name: "", kind: kind)
        obstacle.name = name.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        obstacle.note = trimmedNote.isEmpty ? nil : trimmedNote
        obstacle.kind = kind
        if existing == nil {
            state.addObstacle(obstacle)
        } else {
            state.updateObstacle(obstacle)
        }
        dismiss()
    }
}
