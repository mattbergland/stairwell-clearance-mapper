import SwiftUI

struct PianoDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let piano: Piano
    var selection: Binding<Piano?>?
    @State private var didChoose = false

    var body: some View {
        List {
            Section("Size") {
                ForEach(piano.dimensionLabels, id: \.label) { item in
                    LabeledContent(item.label) {
                        Text(MeasurementFormatting.dimension(item.value,
                                                             units: state.route.settings.units))
                    }
                }
                LabeledContent("Weight") {
                    Text("\(Int(piano.weightLb)) lb")
                }
                LabeledContent("Moving crew") {
                    Text("\(piano.crewSize) people (rule of thumb)")
                }
            }
            Section {
                Text("Typical dimensions — measure the actual piano if unsure")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .navigationTitle(piano.name)
        .safeAreaInset(edge: .bottom) {
            Button {
                state.choosePiano(piano)
                selection?.wrappedValue = piano
                didChoose = true
                if selection != nil {
                    dismiss()
                } else {
                    state.selectedTab = 0
                }
            } label: {
                Text(didChoose && selection == nil ? "Using this piano ✓" : "Use this piano")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.bar)
            .accessibilityIdentifier("useThisPiano")
        }
    }
}
