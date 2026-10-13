import SwiftUI

/// The route tab: picked piano plus obstacles in walking order.
struct RouteView: View {
    @Environment(AppState.self) private var state
    @State private var showPianoPicker = false
    @State private var showKindPicker = false
    @State private var confirmClear = false
    @State private var editing: Obstacle?

    var body: some View {
        content
            .navigationTitle("Route")
            .toolbar {
                if !state.route.obstacles.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Load sample job") { state.loadSampleJob() }
                            .accessibilityIdentifier("loadSampleJob")
                        Button("Clear route", role: .destructive) { confirmClear = true }
                            .disabled(state.route.obstacles.isEmpty && state.route.piano == nil)
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("routeMenu")
                }
            }
            .confirmationDialog("Remove the piano and every obstacle?",
                                isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear route", role: .destructive) { state.clearRoute() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showPianoPicker) {
                NavigationStack {
                    PianoPickerView()
                }
            }
            .sheet(item: $editing) { obstacle in
                NavigationStack {
                    ObstacleFormView(kindType: obstacle.kindType, existing: obstacle)
                }
            }
            .sheet(isPresented: $showKindPicker) {
                NavigationStack {
                    ObstacleKindPicker()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if state.route.piano == nil && state.route.obstacles.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No route yet", systemImage: "map")
        } description: {
            Text("Pick a piano, then add each doorway, stair, and turn along the path — in the order you'll walk them.")
        } actions: {
            Button("Choose a piano") { showPianoPicker = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("choosePianoEmpty")
            Button("Load sample job") { state.loadSampleJob() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("loadSampleJobEmpty")
            Button("Add obstacle") { showKindPicker = true }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("addObstacleEmpty")
        }
    }

    private var list: some View {
        List {
            if let jobName = state.route.jobName {
                Section {
                    Text(jobName)
                        .font(.headline)
                        .accessibilityIdentifier("jobName")
                }
            }
            Section {
                Button {
                    showPianoPicker = true
                } label: {
                    HStack {
                        if let piano = state.route.piano {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(piano.name).font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(piano.category.displayName) · \(Int(piano.weightLb)) lb")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Choose a piano", systemImage: "music.note")
                                .font(.headline)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                .accessibilityIdentifier("pianoCard")
            }

            Section("Obstacles, in walking order") {
                ForEach(state.route.obstacles) { obstacle in
                    Button {
                        editing = obstacle
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(obstacle.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(summary(of: obstacle))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("obstacle.\(obstacle.name)")
                }
                .onDelete { state.route.obstacles.remove(atOffsets: $0) }
                .onMove { state.route.obstacles.move(fromOffsets: $0, toOffset: $1) }
            }

            Section {
                Button {
                    showKindPicker = true
                } label: {
                    Label("Add obstacle", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("addObstacle")
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    private func summary(of obstacle: Obstacle) -> String {
        let units = state.route.settings.units
        func d(_ v: Double) -> String { MeasurementFormatting.dimension(v, units: units) }
        switch obstacle.kind {
        case let .doorway(w, h):
            return "Doorway — \(d(w)) wide × \(d(h)) tall"
        case let .straightStairs(w, head, rise, run):
            return "Stairs — \(d(w)) wide, \(d(head)) headroom, \(d(rise))/\(d(run)) steps"
        case let .turn90(a, b, ceiling):
            return "90° turn — \(d(a)) in / \(d(b)) out, \(d(ceiling)) ceiling"
        case let .uTurn(a, landing, b, ceiling):
            return "U-turn — \(d(a)) in, \(d(landing)) landing, \(d(b)) out, \(d(ceiling)) ceiling"
        }
    }
}

/// The same library list, but tapping a piano's "Use this piano" sets it and closes.
struct PianoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var picked: Piano?

    var body: some View {
        PianosView(selection: $picked)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: picked) { _, newValue in
                if newValue != nil { dismiss() }
            }
    }
}

/// Lets the user pick which of the four obstacle kinds to add.
struct ObstacleKindPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var state
    @State private var chosen: Obstacle.KindType?

    var body: some View {
        List(Obstacle.KindType.allCases, id: \.self) { kind in
            Button {
                chosen = kind
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title).font(.headline).foregroundStyle(.primary)
                    Text(kind.explanation).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(minHeight: 44, alignment: .leading)
            }
            .accessibilityIdentifier("kind.\(kind.rawValue)")
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .navigationTitle("Add obstacle")
        .navigationDestination(item: $chosen) { kind in
            ObstacleFormView(kindType: kind, existing: nil)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
