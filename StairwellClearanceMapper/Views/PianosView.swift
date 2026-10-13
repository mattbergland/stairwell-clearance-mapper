import SwiftUI

/// The built-in piano library. Also usable as a picker sheet (`selection` set).
struct PianosView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var showCustomForm = false
    var selection: Binding<Piano?>?

    private var filtered: [Piano] {
        guard case let .loaded(pianos) = state.libraryState else { return [] }
        if search.isEmpty { return pianos }
        return pianos.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        Group {
            switch state.libraryState {
            case .loading:
                ProgressView("Loading the piano list…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load the piano list", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") {
                        Task { await state.loadLibrary() }
                    }
                    .accessibilityIdentifier("libraryRetry")
                }
            case .loaded:
                list
            }
        }
        .navigationTitle("Pianos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCustomForm = true
                } label: {
                    Label("Custom size", systemImage: "plus")
                }
                .accessibilityIdentifier("customSizeButton")
            }
        }
        .sheet(isPresented: $showCustomForm) {
            NavigationStack {
                CustomPianoView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(PianoCategory.allCases, id: \.self) { category in
                let pianos = filtered.filter { $0.category == category }
                if !pianos.isEmpty {
                    Section(category.displayName) {
                        ForEach(pianos) { piano in
                            NavigationLink {
                                PianoDetailView(piano: piano, selection: selection)
                            } label: {
                                PianoRow(piano: piano, units: state.route.settings.units)
                            }
                            .accessibilityIdentifier("pianoRow.\(piano.id)")
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Search pianos")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }
}

struct PianoRow: View {
    let piano: Piano
    let units: MeasurementUnits

    private var sizeText: String {
        switch piano.category {
        case .upright, .pumpOrgan:
            return uprightSizeText
        case .grand, .squareGrand:
            return MeasurementFormatting.dimensionPair(piano.length ?? 0,
                                                       piano.width ?? 0,
                                                       units: units)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(piano.name).font(.headline)
            Text("\(piano.era) · \(sizeText) · \(Int(piano.weightLb)) lb")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

/// Piano row size text helper kept out of the view body for clarity.
private extension PianoRow {
    var uprightSizeText: String {
        let w = MeasurementFormatting.dimension(piano.width ?? 0, units: units)
        let h = MeasurementFormatting.dimension(piano.height ?? 0, units: units)
        return "\(w) wide × \(h) tall"
    }
}
