import SwiftUI

/// Form for entering a piano that isn't in the library.
struct CustomPianoView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: PianoCategory = .upright
    @State private var weightText = ""
    @State private var dim1 = MeasurementDraft() // width or length
    @State private var dim2 = MeasurementDraft() // depth/height or width/thickness
    @State private var dim3 = MeasurementDraft()
    @FocusState private var focus: FieldFocus?

    /// Every focusable field in entry order.
    private var focusOrder: [FieldFocus] {
        var order: [FieldFocus] = [.name]
        for id in ["customDim1", "customDim2", "customDim3"] {
            if units == .inches {
                order.append(.measurement(key: id, part: .feet))
                order.append(.measurement(key: id, part: .inches))
            } else {
                order.append(.measurement(key: id, part: .cm))
            }
        }
        order.append(.weight)
        return order
    }

    private func advanceFocus() {
        guard let focus,
              let index = focusOrder.firstIndex(of: focus),
              index + 1 < focusOrder.count else {
            self.focus = nil
            return
        }
        self.focus = focusOrder[index + 1]
    }

    private var units: MeasurementUnits { state.route.settings.units }

    private var dimLabels: [String] {
        switch category {
        case .upright, .pumpOrgan:
            return ["Width (left to right)", "Depth (front to back)", "Height"]
        case .grand, .squareGrand:
            return ["Length (keyboard to tail)", "Width", "Case thickness (legs, lyre & lid off)"]
        }
    }

    private var weightValid: Bool {
        (Double(weightText) ?? 0) > 0
    }

    private var allValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && weightValid
            && dim1.isValid(units: units)
            && dim2.isValid(units: units)
            && dim3.isValid(units: units)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("e.g. “Grandma’s upright”", text: $name)
                    .focused($focus, equals: .name)
                    .submitLabel(.next)
                    .onSubmit(advanceFocus)
                    .accessibilityIdentifier("customPianoName")
            }
            Section("Type") {
                Picker("Type", selection: $category) {
                    ForEach(PianoCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Size") {
                MeasurementField(label: dimLabels[0],
                                 hint: "Measure the actual piano if you can.",
                                 draft: dim1,
                                 units: units,
                                 fieldID: "customDim1",
                                 focus: $focus,
                                 onSubmit: advanceFocus)
                MeasurementField(label: dimLabels[1],
                                 hint: "Measure the actual piano if you can.",
                                 draft: dim2,
                                 units: units,
                                 fieldID: "customDim2",
                                 focus: $focus,
                                 onSubmit: advanceFocus)
                MeasurementField(label: dimLabels[2],
                                 hint: "Measure the actual piano if you can.",
                                 draft: dim3,
                                 units: units,
                                 fieldID: "customDim3",
                                 focus: $focus,
                                 onSubmit: advanceFocus)
            }
            Section("Weight (lb)") {
                TextField("e.g. 550", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: .weight)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .accessibilityIdentifier("customPianoWeight")
                if !weightText.isEmpty && !weightValid {
                    FieldError("Weight must be a number above zero.")
                }
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .navigationTitle("Custom size")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!allValid)
                    .accessibilityIdentifier("saveCustomPiano")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button("Next") { advanceFocus() }
                    .disabled(focus == focusOrder.last || focus == nil)
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private func save() {
        var piano = Piano(id: "custom-\(UUID().uuidString)",
                          name: name.trimmingCharacters(in: .whitespaces),
                          era: "Custom",
                          category: category,
                          weightLb: Double(weightText) ?? 0)
        switch category {
        case .upright, .pumpOrgan:
            piano.width = dim1.inches(units: units)
            piano.depth = dim2.inches(units: units)
            piano.height = dim3.inches(units: units)
        case .grand, .squareGrand:
            piano.length = dim1.inches(units: units)
            piano.width = dim2.inches(units: units)
            piano.caseThickness = dim3.inches(units: units)
        }
        state.choosePiano(piano)
        dismiss()
        state.selectedTab = 0
    }
}
