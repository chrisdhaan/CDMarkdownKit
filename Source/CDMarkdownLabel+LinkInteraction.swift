//
//  CDMarkdownLabel+LinkInteraction.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 8/29/26.
//
//  Copyright © 2016-2026 Christopher de Haan <contact@christopherdehaan.me>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if os(iOS)
    import SafariServices
#endif

#if os(iOS) || os(tvOS) || os(visionOS)

    import UIKit

    extension CDMarkdownLabel {

        // MARK: - Action Sheet

        private func makeOpenAction(for url: URL) -> UIAlertAction {
            UIAlertAction(title: "Open", style: .default) { _ in
                self.delegate?.didSelect(url)
            }
        }

        #if os(iOS) && !targetEnvironment(macCatalyst)
            private func addReadingListAction(to controller: UIAlertController, for url: URL) {
                guard SSReadingList.supportsURL(url) else { return }
                controller.addAction(UIAlertAction(title: "Add to Reading List", style: .default) { _ in
                    do {
                        try SSReadingList.default()?.addItem(with: url, title: nil, previewText: nil)
                    } catch {
                        print("Error adding item to reading list.")
                    }
                })
            }

            private func addCopyAndShareActions(to controller: UIAlertController,
                                                for url: URL,
                                                presentingFrom parentViewController: UIViewController?) {
                controller.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                    UIPasteboard.general.string = url.absoluteString
                })
                controller.addAction(UIAlertAction(title: "Share...", style: .default) { _ in
                    let activityViewController = UIActivityViewController(activityItems: [url],
                                                                          applicationActivities: [])
                    parentViewController?.present(activityViewController, animated: true, completion: nil)
                })
            }
        #endif

        private func findParentViewController() -> UIViewController? {
            var parentViewController: UIViewController?
            var parentResponder: UIResponder? = self
            while parentResponder != nil {
                parentResponder = parentResponder!.next
                if let viewController = parentResponder as? UIViewController {
                    parentViewController = viewController
                }
            }
            return parentViewController
        }

        private func displayActionController(forUrl url: URL) {
            let parentViewController = findParentViewController()
            let actionController = UIAlertController(title: nil,
                                                     message: nil,
                                                     preferredStyle: .actionSheet)
            actionController.addAction(makeOpenAction(for: url))
            #if os(iOS) && !targetEnvironment(macCatalyst)
                addReadingListAction(to: actionController, for: url)
                addCopyAndShareActions(to: actionController, for: url, presentingFrom: parentViewController)
            #endif
            actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            parentViewController?.present(actionController, animated: true, completion: nil)
        }

        // MARK: - Touch Handling

        internal func onTouch(_ touch: UITouch) -> Bool {
            let location = touch.location(in: self)
            var avoidSuperCall = false

            switch touch.phase {
            case .began,
                 .moved:
                if let urlRange = self.urlRange(at: location) {
                    let locationMatch = urlRange.range.location == self.selectedURLRange?.range.location
                    let lengthMatch = urlRange.range.length == self.selectedURLRange?.range.length
                    if !locationMatch || !lengthMatch {
                        self.selectedURLRange = urlRange
                    }
                    avoidSuperCall = true
                } else {
                    self.selectedURLRange = nil
                }
            case .ended:
                guard let selectedRange = self.selectedURLRange else { return avoidSuperCall }

                self.displayActionController(forUrl: selectedRange.url)

                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    self?.selectedURLRange = nil
                }
                avoidSuperCall = true
            case .cancelled:
                self.selectedURLRange = nil
            case .stationary:
                break
            default:
                break
            }

            return avoidSuperCall
        }

        // MARK: - Link Range Lookup

        internal func parseTextAndExtractURLRanges(_ attrString: NSAttributedString) {
            urlRanges.removeAll()
            attrString.enumerateLinkAttribute(in: NSRange(location: 0,
                                                          length: attrString.length),
                                              options: [.longestEffectiveRangeNotRequired]) { value, range, _ in

                if let value = value as? NSURL,
                   let urlString = value.absoluteString,
                   let url = URL(string: urlString) {
                    self.urlRanges.append((url, range))
                }
            }
        }

        /// Internal (not `private`) — this is the core tap-to-link hit-testing entry point
        /// (dispatches to the TK1/TK2 variants below). Exposed so tests can drive it directly
        /// with a `CGPoint`, since `UITouch` has no public initializer and can't be synthesized
        /// in a unit test.
        internal func urlRange(at location: CGPoint) -> URLRange? {
            if #available(iOS 16.0, tvOS 16.0, *),
               let stack = tk2Stack as? TK2Stack,
               let textStorage = stack.layoutManager.textContentManager as? NSTextContentStorage {
                urlRangeTK2(at: location, layoutManager: stack.layoutManager, storage: textStorage)
            } else {
                urlRangeTK1(at: location)
            }
        }

        @available(iOS 16.0, tvOS 16.0, *)
        private func urlRangeTK2(at location: CGPoint, layoutManager: NSTextLayoutManager, storage: NSTextContentStorage) -> URLRange? {
            guard let textStorage = storage.textStorage, textStorage.length > 0 else { return nil }

            let glyphsPosition = calculateGlyphsPositionInView()
            let adjustedLocation = CGPoint(
                x: location.x - glyphsPosition.x,
                y: location.y - glyphsPosition.y
            )

            var matchedCharIndex: Int?
            enumerateTK2Fragments(layoutManager) { fragment in
                guard fragment.layoutFragmentFrame.contains(adjustedLocation) else { return true }

                for lineFragment in fragment.textLineFragments {
                    let lineOrigin = CGPoint(
                        x: fragment.layoutFragmentFrame.minX + lineFragment.typographicBounds.minX,
                        y: fragment.layoutFragmentFrame.minY + lineFragment.typographicBounds.minY
                    )
                    let lineFrame = CGRect(origin: lineOrigin, size: lineFragment.typographicBounds.size)
                    guard lineFrame.contains(adjustedLocation) else { continue }

                    let localPoint = CGPoint(
                        x: adjustedLocation.x - lineOrigin.x,
                        y: adjustedLocation.y - lineOrigin.y
                    )
                    matchedCharIndex = lineFragment.characterIndex(for: localPoint)
                    return false
                }
                return true
            }

            guard let charIndex = matchedCharIndex else { return nil }
            for urlRange in urlRanges {
                if charIndex >= urlRange.range.location, charIndex < urlRange.range.location + urlRange.range.length {
                    return urlRange
                }
            }
            return nil
        }

        private func urlRangeTK1(at location: CGPoint) -> URLRange? {
            guard customTextStorage.length > 0 else { return nil }

            // Mirrors urlRangeTK2's adjustment: boundingRect/glyphIndex operate in the text
            // container's own coordinate space, which doesn't include the vertical-centering
            // offset drawText(in:)/calculateGlyphsPositionInView() apply when the text is
            // shorter than the label's bounds. Without subtracting it here, a tap on a
            // vertically-centered short label would compare against the wrong rect and never
            // register a hit.
            let glyphsPosition = calculateGlyphsPositionInView()
            let adjustedLocation = CGPoint(
                x: location.x - glyphsPosition.x,
                y: location.y - glyphsPosition.y
            )

            let boundingRect = customLayoutManager.boundingRect(forGlyphRange: NSRange(location: 0,
                                                                                       length: customTextStorage.length),
                                                                in: customTextContainer)

            guard boundingRect.contains(adjustedLocation) else { return nil }

            let index = customLayoutManager.glyphIndex(for: adjustedLocation,
                                                       in: customTextContainer)

            for urlRange in urlRanges {
                if index >= urlRange.range.location, index < urlRange.range.location + urlRange.range.length {
                    return urlRange
                }
            }

            return nil
        }
    }

    // MARK: - LayoutManagerDelegate Methods

    extension CDMarkdownLabel: @preconcurrency NSLayoutManagerDelegate {
        public func layoutManager(_ layoutManager: NSLayoutManager,
                                  shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
            var range = NSRange()
            // Don't allow line breaks on URL's

            let linkURL = layoutManager.textStorage?.linkAttribute(at: charIndex,
                                                                   effectiveRange: &range)

            return !((linkURL != nil) && (charIndex > range.location) && (charIndex <= NSMaxRange(range)))
        }
    }

    // MARK: - UIGestureRecognizerDelegate Methods

    extension CDMarkdownLabel: UIGestureRecognizerDelegate {

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                      shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                      shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }

#endif
