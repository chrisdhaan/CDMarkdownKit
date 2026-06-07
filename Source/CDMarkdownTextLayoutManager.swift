#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 16.0, tvOS 16.0, *)
final class CDMarkdownTextLayoutManager: NSTextLayoutManager {

    var roundAllCorners: Bool = false {
        didSet {
            if oldValue != roundAllCorners {
                invalidateLayout(for: textContentManager?.documentRange ?? .init())
            }
        }
    }

    static func makeDefault() -> CDMarkdownTextLayoutManager {
        let manager = CDMarkdownTextLayoutManager()
        manager.delegate = manager
        return manager
    }
}

@available(iOS 16.0, tvOS 16.0, *)
extension CDMarkdownTextLayoutManager: NSTextLayoutManagerDelegate {

    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                           textLayoutFragmentFor location: any NSTextLocation,
                           in textElement: NSTextElement) -> NSTextLayoutFragment {
        let fragment = CDMarkdownTextLayoutFragment(textElement: textElement,
                                                    range: textElement.elementRange)
        fragment.roundAllCorners = roundAllCorners
        return fragment
    }
}
#endif
