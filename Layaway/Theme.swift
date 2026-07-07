import SwiftUI

/// Layaway palette: slate-blue ledger + warm gold bead progress.
/// Distinct from every prior app (no mint/copper, no cream/ink, no navy/coral).
enum Theme {
    static let slate = Color(red: 0.20, green: 0.24, blue: 0.33)
    static let slateDeep = Color(red: 0.12, green: 0.15, blue: 0.22)
    static let gold = Color(red: 0.80, green: 0.64, blue: 0.24)
    static let goldBright = Color(red: 0.93, green: 0.76, blue: 0.35)
    static let beadEmpty = Color(red: 0.85, green: 0.86, blue: 0.90)
    static let ink = Color(red: 0.14, green: 0.16, blue: 0.20)
    static let background = Color(red: 0.96, green: 0.96, blue: 0.98)
    static let cardBackground = Color.white

    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let numberFont = Font.system(size: 40, weight: .heavy, design: .rounded)
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }
}
