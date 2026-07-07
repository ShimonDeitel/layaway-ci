import SwiftUI

/// Layaway's identity: a "punch card" metaphor for installment plans — graphite
/// card stock with a warm copper/rust punch accent. Deliberately distinct from
/// every sibling app: not Beacon's neutral-slate/amber-glow, not the
/// cream/ink-navy "luxury editorial" look (Ledger family), not any brown/sage
/// app. Graphite is cool and industrial; copper is warm and tactile — evokes
/// a physical ticket/stub being punched each time a payment clears.
enum LWTheme {
    static let backdrop = Color(red: 0.098, green: 0.102, blue: 0.114)
    static let card = Color(red: 0.145, green: 0.153, blue: 0.169)
    static let cardRaised = Color(red: 0.184, green: 0.192, blue: 0.212)
    static let punchHole = Color(red: 0.098, green: 0.102, blue: 0.114)
    static let ink = Color(red: 0.945, green: 0.937, blue: 0.918)
    static let inkFaded = Color(red: 0.945, green: 0.937, blue: 0.918).opacity(0.54)
    static let rule = Color.white.opacity(0.09)

    static let copper = Color(red: 0.788, green: 0.443, blue: 0.263)
    static let copperBright = Color(red: 0.902, green: 0.573, blue: 0.361)
    static let copperDim = Color(red: 0.788, green: 0.443, blue: 0.263).opacity(0.28)

    static let paidGreen = Color(red: 0.404, green: 0.643, blue: 0.427)
    static let dueSoon = Color(red: 0.847, green: 0.647, blue: 0.263)
    static let overdue = Color(red: 0.804, green: 0.322, blue: 0.298)

    static let displayFont = Font.system(size: 46, weight: .bold, design: .rounded)
    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let monoFont = Font.system(.body, design: .monospaced)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func punch() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
