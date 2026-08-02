#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit

    /// Plain mutable reference shared between a `CDMarkdownTextLayoutDelegate` and every
    /// `CDMarkdownTextLayoutFragment` it creates, so toggling `roundAllCorners` after fragments
    /// already exist is visible to all of them without needing actor-isolated access at draw
    /// time. `NSTextLayoutManager` reuses already-created fragment instances across
    /// `invalidateLayout(for:)` rather than recreating them, so a value copied onto each
    /// fragment at creation time would never see a later toggle; a shared reference always
    /// reflects the delegate's current value. `roundAllCorners` is only ever written from the
    /// delegate's `@MainActor` setter and only ever read from drawing code that UIKit guarantees
    /// runs on the main thread, so the lack of actor isolation here is safe in practice despite
    /// being unenforced by the compiler.
    @available(iOS 16.0, tvOS 16.0, *)
    final class CDMarkdownRoundAllCornersBox: @unchecked Sendable {
        var value = false
    }

    @available(iOS 16.0, tvOS 16.0, *)
    @MainActor
    final class CDMarkdownTextLayoutDelegate: NSObject, @preconcurrency NSTextLayoutManagerDelegate {

        let roundAllCornersBox = CDMarkdownRoundAllCornersBox()

        var roundAllCorners: Bool {
            get { roundAllCornersBox.value }
            set {
                guard roundAllCornersBox.value != newValue else { return }
                roundAllCornersBox.value = newValue
                guard let manager = layoutManager else { return }
                manager.invalidateLayout(for: manager.documentRange)
            }
        }

        weak var layoutManager: NSTextLayoutManager?

        func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                               textLayoutFragmentFor location: any NSTextLocation,
                               in textElement: NSTextElement) -> NSTextLayoutFragment {
            let fragment = CDMarkdownTextLayoutFragment(textElement: textElement,
                                                        range: textElement.elementRange)
            fragment.roundAllCornersBox = roundAllCornersBox
            return fragment
        }
    }
#endif
