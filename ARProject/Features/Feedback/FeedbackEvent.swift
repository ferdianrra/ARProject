import Foundation

enum FeedbackTone {
    case positive
    case negative
}

enum FeedbackHaptic {
    case success
    case warning
    case light
}

enum FeedbackSound {
    case positiveChime
    case negativeBuzz
}

/// A single feedback moment (banner + haptic + sound), shared across every
/// mode so the app speaks one consistent "language" for good/bad/minor
/// actions instead of each feature building its own. `id` makes every event
/// distinct even if tone/haptic/sound repeat, so SwiftUI's sensoryFeedback
/// and the toast dismiss timer both re-trigger on each new occurrence.
struct FeedbackEvent: Equatable {
    let id = UUID()
    let message: String?
    let tone: FeedbackTone
    let haptic: FeedbackHaptic
    let sound: FeedbackSound?
}
