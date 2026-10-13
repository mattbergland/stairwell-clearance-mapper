import SwiftUI

/// Text a measurement field is made from: feet+inches, or one cm value.
final class MeasurementDraft: ObservableObject {
    @Published var feet = ""
    @Published var inches = ""
    @Published var cm = ""

    init() {}

    init(inches total: Double) {
        feet = String(Int(total / 12))
        inches = (total.truncatingRemainder(dividingBy: 12))
            .formatted(.number.precision(.fractionLength(0...2)))
        cm = String(Int((total * MeasurementFormatting.cmPerInch).rounded()))
    }

    /// Total inches, or nil if the fields can't be parsed.
    func inches(units: MeasurementUnits) -> Double? {
        switch units {
        case .inches:
            let f = feet.isEmpty ? 0 : Double(feet)
            let i = inches.isEmpty ? 0 : Double(inches)
            guard let f, let i else { return nil }
            return f * 12 + i
        case .centimeters:
            guard let value = Double(cm) else { return nil }
            return value / MeasurementFormatting.cmPerInch
        }
    }

    /// 6–600 inches — the sane range for a doorway, stair, or piano part.
    func isValid(units: MeasurementUnits) -> Bool {
        guard let value = inches(units: units) else { return false }
        return (6...600).contains(value)
    }

    func isEmpty(units: MeasurementUnits) -> Bool {
        switch units {
        case .inches: return feet.isEmpty && inches.isEmpty
        case .centimeters: return cm.isEmpty
        }
    }
}

/// Which field currently has the keyboard, tracked at the form level so
/// Return / Next can walk through every field in order.
enum FieldFocus: Hashable {
    case name
    case note
    case weight
    case measurement(key: String, part: MeasurementPart)
}

enum MeasurementPart: Hashable {
    case feet
    case inches
    case cm
}

/// One measurement with a label, a plain-language "what to measure" hint,
/// and inline validation. Inches mode shows separate ft and in fields.
struct MeasurementField: View {
    let label: String
    let hint: String
    @ObservedObject var draft: MeasurementDraft
    let units: MeasurementUnits
    let fieldID: String
    var focus: FocusState<FieldFocus?>.Binding
    var onSubmit: () -> Void = {}

    /// The focus values this field owns, in entry order.
    var focusValues: [FieldFocus] {
        switch units {
        case .inches:
            return [.measurement(key: fieldID, part: .feet),
                    .measurement(key: fieldID, part: .inches)]
        case .centimeters:
            return [.measurement(key: fieldID, part: .cm)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.headline)
            Text("What to measure: \(hint)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if units == .inches {
                HStack {
                    TextField("ft", text: $draft.feet)
                        .keyboardType(.decimalPad)
                        .frame(minWidth: 60)
                        .textFieldStyle(.roundedBorder)
                        .focused(focus, equals: .measurement(key: fieldID, part: .feet))
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                        .accessibilityIdentifier("\(fieldID).feet")
                        .accessibilityLabel("\(label), feet")
                    Text("ft").foregroundStyle(.secondary)
                    TextField("in", text: $draft.inches)
                        .keyboardType(.decimalPad)
                        .frame(minWidth: 60)
                        .textFieldStyle(.roundedBorder)
                        .focused(focus, equals: .measurement(key: fieldID, part: .inches))
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                        .accessibilityIdentifier("\(fieldID).inches")
                        .accessibilityLabel("\(label), inches")
                    Text("in").foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    TextField("cm", text: $draft.cm)
                        .keyboardType(.decimalPad)
                        .frame(minWidth: 80)
                        .textFieldStyle(.roundedBorder)
                        .focused(focus, equals: .measurement(key: fieldID, part: .cm))
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                        .accessibilityIdentifier("\(fieldID).cm")
                        .accessibilityLabel("\(label), centimeters")
                    Text("cm").foregroundStyle(.secondary)
                }
            }
            if showsError {
                FieldError("Needs to be between \(units == .inches ? "6 and 600 in" : "15 and 1524 cm").")
            }
        }
        .padding(.vertical, 4)
    }

    private var showsError: Bool {
        !draft.isEmpty(units: units) && !draft.isValid(units: units)
    }
}

struct FieldError: View {
    let message: String
    init(_ message: String) { self.message = message }

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .accessibilityIdentifier("fieldError")
    }
}
