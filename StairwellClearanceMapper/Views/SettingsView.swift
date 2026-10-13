import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state

    private var units: MeasurementUnits { state.route.settings.units }

    /// Stepper step in the current units, stored in inches.
    private var stepInInches: Double {
        units == .inches ? 0.25 : 0.5 / MeasurementFormatting.cmPerInch
    }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Show measurements in", selection: unitsBinding) {
                    ForEach(MeasurementUnits.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("unitsPicker")
            }

            Section("Allowances") {
                Stepper(value: paddingBinding, in: 0...2, step: stepInInches) {
                    LabeledContent("Padding per side (blankets, board)") {
                        Text(MeasurementFormatting.clearance(state.route.settings.paddingPerSide,
                                                             units: units))
                    }
                }
                .accessibilityIdentifier("paddingStepper")
                Stepper(value: marginBinding, in: 0...3, step: stepInInches) {
                    LabeledContent("Safety margin") {
                        Text(MeasurementFormatting.clearance(state.route.settings.safetyMargin,
                                                             units: units))
                    }
                }
                .accessibilityIdentifier("marginStepper")
            }

            Section("How the math works") {
                Text("""
                     We add your padding to each side of the piano, then check every doorway, stair, and turn — in every sensible way to carry it. \
                     If the tightest spot still leaves your safety margin, it's a “Fits”. Below the margin is “Tight”; negative means “Won't fit”.
                     """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Text("Estimates only — always confirm on site.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reset to defaults", role: .destructive) {
                    state.route.settings = Settings()
                }
                .frame(minHeight: 44)
                .accessibilityIdentifier("resetSettings")
            }
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
        .navigationTitle("Settings")
    }

    private var unitsBinding: Binding<MeasurementUnits> {
        Binding(get: { state.route.settings.units },
                set: { state.route.settings.units = $0 })
    }

    private var paddingBinding: Binding<Double> {
        Binding(get: { state.route.settings.paddingPerSide },
                set: { state.route.settings.paddingPerSide = $0 })
    }

    private var marginBinding: Binding<Double> {
        Binding(get: { state.route.settings.safetyMargin },
                set: { state.route.settings.safetyMargin = $0 })
    }
}
