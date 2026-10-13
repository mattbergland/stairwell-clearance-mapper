import Foundation

/// Formats measurements stored in inches for display in the current units.
enum MeasurementFormatting {

    static let cmPerInch = 2.54

    /// A single dimension: values of 60 in or more show as feet and inches
    /// (67 → 5′7″), smaller values as inches with ¼/½/¾ fractions (56.5 → 56½″).
    /// In centimeter mode everything shows as whole centimeters ("170 cm").
    static func dimension(_ inches: Double, units: MeasurementUnits) -> String {
        switch units {
        case .centimeters:
            return "\(Int((inches * cmPerInch).rounded())) cm"
        case .inches:
            if inches >= 60 {
                let feet = Int(inches / 12)
                let remainder = inches - Double(feet) * 12
                return "\(feet)′\(fractionString(remainder))″"
            }
            return "\(fractionString(inches))″"
        }
    }

    /// A pair of dimensions joined with ×, e.g. "5′7″ × 56½″" or "170 × 144 cm".
    static func dimensionPair(_ a: Double, _ b: Double, units: MeasurementUnits) -> String {
        switch units {
        case .centimeters:
            let cmA = Int((a * cmPerInch).rounded())
            let cmB = Int((b * cmPerInch).rounded())
            return "\(cmA) × \(cmB) cm"
        case .inches:
            return "\(dimension(a, units: units)) × \(dimension(b, units: units))"
        }
    }

    /// A small clearance amount for "to spare / short" messages.
    /// Inches keep one decimal ("20.5 in"), centimeters round to whole cm.
    static func clearance(_ inches: Double, units: MeasurementUnits) -> String {
        switch units {
        case .centimeters:
            return "\(Int((abs(inches) * cmPerInch).rounded())) cm"
        case .inches:
            let rounded = (abs(inches) * 10).rounded() / 10
            if rounded == rounded.rounded() {
                return "\(Int(rounded)) in"
            }
            return String(format: "%.1f in", rounded)
        }
    }

    /// Spelled-out version for VoiceOver, e.g. "20 and a half inches".
    static func spokenClearance(_ inches: Double, units: MeasurementUnits) -> String {
        switch units {
        case .centimeters:
            return "\(Int((abs(inches) * cmPerInch).rounded())) centimeters"
        case .inches:
            let value = abs(inches)
            let whole = Int(value)
            let frac = value - Double(whole)
            let fracWord: String
            if frac >= 0.875 || frac < 0.125 {
                fracWord = ""
            } else if frac < 0.375 {
                fracWord = " and a quarter"
            } else if frac < 0.625 {
                fracWord = " and a half"
            } else {
                fracWord = " and three quarters"
            }
            let roundedWhole = frac >= 0.875 ? whole + 1 : whole
            return "\(roundedWhole)\(fracWord) inches"
        }
    }

    /// 56.5 → "56½", 7.25 → "7¼", 8 → "8". Rounds to the nearest quarter.
    static func fractionString(_ inches: Double) -> String {
        let whole = Int(inches)
        let frac = inches - Double(whole)
        let quarters = Int((frac * 4).rounded())
        switch quarters {
        case 0:
            return "\(whole)"
        case 1:
            return "\(whole)¼"
        case 2:
            return "\(whole)½"
        case 3:
            return "\(whole)¾"
        default:
            return "\(whole + 1)"
        }
    }
}
