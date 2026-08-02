#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit

    @available(iOS 16.0, tvOS 16.0, *)
    @MainActor
    final class CDMarkdownTextLayoutDelegate: NSObject, @preconcurrency NSTextLayoutManagerDelegate {

        var roundAllCorners: Bool = false {
            didSet {
                guard oldValue != roundAllCorners, let manager = layoutManager else { return }
                manager.invalidateLayout(for: manager.documentRange)
            }
        }

        weak var layoutManager: NSTextLayoutManager?

        func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                               textLayoutFragmentFor location: any NSTextLocation,
                               in textElement: NSTextElement) -> NSTextLayoutFragment {
            CDMarkdownTextLayoutFragment(textElement: textElement,
                                         range: textElement.elementRange)
        }
    }
#endif
