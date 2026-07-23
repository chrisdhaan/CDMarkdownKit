//
//  CDMarkdownLabel.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/14/16.
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

    /// Delegate for handling link selection events in ``CDMarkdownLabel``.
    public protocol CDMarkdownLabelDelegate: AnyObject {
        /// Called when a user taps a link in the label.
        ///
        /// - Parameter url: The URL of the link that was selected.
        ///
        /// Implement this method to handle link navigation, e.g., opening a Safari view controller
        /// or pushing a web view onto the navigation stack.
        func didSelect(_ url: URL)
    }

    typealias URLRange = (url: URL, range: NSRange)

    /// A `UILabel` subclass that renders styled Markdown text with clickable links.
    ///
    /// Use ``CDMarkdownLabel`` to display Markdown-formatted text with automatic link handling.
    /// Set ``attributedText`` with an ``NSAttributedString`` produced by ``CDMarkdownParser``
    /// to display parsed Markdown. Links trigger ``CDMarkdownLabelDelegate`` callbacks.
    @MainActor
    open class CDMarkdownLabel: UILabel {

        /// The custom layout manager used for rendering with rounded-corner backgrounds.
        open var customLayoutManager: CDMarkdownLayoutManager!

        /// The custom text container that manages text layout dimensions and line properties.
        open var customTextContainer: NSTextContainer!

        /// The custom text storage that holds the attributed text and layout information.
        open var customTextStorage: NSTextStorage!

        /// Holds an NSTextLayoutManager on iOS/tvOS 16+.
        private var tk2LayoutManager: Any?

        /// Holds an NSTextContentStorage on iOS/tvOS 16+.
        private var tk2ContentStorage: Any?

        /// Holds a CDMarkdownTextLayoutDelegate on iOS/tvOS 16+.
        private var tk2LayoutDelegate: Any?

        /// Delegate that receives callbacks when links in the label are tapped.
        /// Set this to handle link navigation, e.g., opening URLs in Safari.
        open weak var delegate: CDMarkdownLabelDelegate?

        /// The parser used to render markdown text. Set this before assigning markdown text.
        /// Used to apply accessibility annotations to the attributed text.
        open weak var markdownParser: CDMarkdownParser?

        /// When `true`, all background color regions (code blocks, syntax blocks, etc.) are drawn with rounded corners.
        /// When `false` (default), backgrounds are drawn as rectangles. Set to `true` for a softer appearance.
        open var roundAllCorners: Bool = false {
            didSet {
                if #available(iOS 16.0, tvOS 16.0, *),
                   let delegate = tk2LayoutDelegate as? CDMarkdownTextLayoutDelegate {
                    delegate.roundAllCorners = roundAllCorners
                } else {
                    if let layoutManager = self.customLayoutManager {
                        layoutManager.roundAllCorners = roundAllCorners
                    }
                }
                setNeedsDisplay()
            }
        }

        override open var frame: CGRect {
            get {
                super.frame
            }
            set {
                super.frame = newValue
                if let textContainer = self.customTextContainer {
                    textContainer.size = self.bounds.size
                }
            }
        }
        override open var bounds: CGRect {
            get {
                super.bounds
            }
            set {
                super.bounds = newValue
                if let textContainer = self.customTextContainer {
                    textContainer.size = self.bounds.size
                }
            }
        }
        override open var attributedText: NSAttributedString! {
            get {
                super.attributedText
            }
            set {
                guard let newValue else {
                    urlRanges.removeAll()
                    if #available(iOS 16.0, tvOS 16.0, *),
                       let contentStorage = tk2ContentStorage as? NSTextContentStorage {
                        contentStorage.textStorage?.setAttributedString(NSAttributedString())
                    } else if let customTextStorage {
                        customTextStorage.setAttributedString(NSAttributedString())
                    }
                    #if os(iOS) || os(visionOS)
                        self.accessibilityAttributedLabel = nil
                    #endif
                    setNeedsDisplay()
                    return
                }

                parseTextAndExtractURLRanges(newValue)

                if #available(iOS 16.0, tvOS 16.0, *),
                   let contentStorage = tk2ContentStorage as? NSTextContentStorage {
                    if let textStorage = contentStorage.textStorage {
                        textStorage.setAttributedString(newValue)
                    } else {
                        let textStorage = NSTextStorage(attributedString: newValue)
                        contentStorage.textStorage = textStorage
                    }
                } else if customTextContainer != nil,
                          let layoutManager = customLayoutManager {
                    customTextStorage = NSTextStorage(attributedString: newValue)
                    customTextStorage.addLayoutManager(layoutManager)
                    layoutManager.textStorage = customTextStorage
                }

                #if os(iOS) || os(visionOS)
                    if let parser = markdownParser {
                        self.accessibilityAttributedLabel = parser.accessibilityAttributedString(from: newValue)
                    }
                #endif

                setNeedsDisplay()
            }
        }

        private var selectedURLRange: URLRange?
        private lazy var urlRanges = [URLRange]()

        override public init(frame: CGRect) {
            super.init(frame: frame)
            self.configure()
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.configure()
        }

        override open func layoutSubviews() {
            super.layoutSubviews()

            self.customTextContainer.size = self.bounds.size
        }

        /// Configures the label's custom layout manager, text container, and text storage.
        ///
        /// Called automatically during initialization. On iOS 16+, this uses TextKit 2 with
        /// ``CDMarkdownTextLayoutDelegate``. On iOS 15, this uses TextKit 1 with ``CDMarkdownLayoutManager``.
        open func configure() {
            isUserInteractionEnabled = true

            if #available(iOS 16.0, tvOS 16.0, *) {
                configureTK2()
            } else {
                configureTK1()
            }
        }

        @available(iOS 16.0, tvOS 16.0, *)
        private func configureTK2() {
            if customTextContainer == nil {
                customTextContainer = NSTextContainer()
                customTextContainer.lineFragmentPadding = 0
                customTextContainer.maximumNumberOfLines = 0
                customTextContainer.lineBreakMode = lineBreakMode
                customTextContainer.size = frame.size
            }

            let contentStorage = NSTextContentStorage()
            guard let layoutManager = contentStorage.textLayoutManagers.first else { return }
            let delegate = CDMarkdownTextLayoutDelegate()
            delegate.layoutManager = layoutManager
            layoutManager.delegate = delegate
            layoutManager.textContainer = customTextContainer
            contentStorage.addTextLayoutManager(layoutManager)

            tk2ContentStorage = contentStorage
            tk2LayoutManager = layoutManager
            tk2LayoutDelegate = delegate
        }

        private func configureTK1() {
            customLayoutManager = CDMarkdownLayoutManager()

            if let textContainer = customTextContainer {
                customLayoutManager.addTextContainer(textContainer)
            } else {
                customTextContainer = NSTextContainer()
                customTextContainer.lineFragmentPadding = 0
                customTextContainer.maximumNumberOfLines = 0
                customTextContainer.lineBreakMode = lineBreakMode
                customTextContainer.size = frame.size

                customLayoutManager.addTextContainer(customTextContainer)
            }
        }

        // MARK: - Layout And Rendering

        override open func textRect(forBounds bounds: CGRect,
                                    limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            // Use our text container to calculate the bounds required. First save our
            // current text container setup
            let savedTextContainerSize = self.customTextContainer.size
            let savedTextContainerNumberOfLines = self.customTextContainer.maximumNumberOfLines
            // Apply the new potential bounds and number of lines
            self.customTextContainer.size = self.bounds.size
            self.customTextContainer.maximumNumberOfLines = numberOfLines
            // Measure the text with the new state
            var textBounds: CGRect
            if #available(iOS 16.0, tvOS 16.0, *), let tk2 = tk2LayoutManager as? NSTextLayoutManager {
                tk2.ensureLayout(for: tk2.documentRange)
                textBounds = .zero
                tk2.enumerateTextLayoutFragments(from: tk2.documentRange.location, options: []) { fragment in
                    textBounds = textBounds.union(fragment.layoutFragmentFrame)
                    return true
                }
            } else {
                textBounds = self.customLayoutManager.usedRect(for: self.customTextContainer)
            }
            // Position the bounds and round up the size for good measure
            textBounds.origin = bounds.origin
            textBounds.size.width = ceil(bounds.width)
            textBounds.size.height = ceil(bounds.height)
            // Take verical alignment into account
            if textBounds.size.height < bounds.size.height {
                let offsetY = (bounds.height - textBounds.size.height) / 2
                textBounds.origin.y += offsetY
            }
            // Restore the old container state before we exit under any circumstances
            self.customTextContainer.size = savedTextContainerSize
            self.customTextContainer.maximumNumberOfLines = savedTextContainerNumberOfLines

            return textBounds
        }

        override open func drawText(in rect: CGRect) {
            if #available(iOS 16.0, tvOS 16.0, *),
               let tk2Manager = tk2LayoutManager as? NSTextLayoutManager {
                drawTextTK2(in: rect, layoutManager: tk2Manager)
            } else {
                drawTextTK1(in: rect)
            }
        }

        @available(iOS 16.0, tvOS 16.0, *)
        private func drawTextTK2(in rect: CGRect, layoutManager: NSTextLayoutManager) {
            guard let context = UIGraphicsGetCurrentContext() else { return }

            let glyphsPosition = calculateGlyphsPositionInView()
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                let fragmentOrigin = CGPoint(
                    x: glyphsPosition.x + fragment.layoutFragmentFrame.origin.x,
                    y: glyphsPosition.y + fragment.layoutFragmentFrame.origin.y
                )
                fragment.draw(at: fragmentOrigin, in: context)
                return true
            }
        }

        private func drawTextTK1(in rect: CGRect) {
            let glyphRange = customLayoutManager.glyphRange(for: customTextContainer)
            let glyphsPosition = calculateGlyphsPositionInView()
            customLayoutManager.drawBackground(forGlyphRange: glyphRange,
                                               at: glyphsPosition)
            customLayoutManager.drawGlyphs(forGlyphRange: glyphRange,
                                           at: glyphsPosition)
        }

        private func calculateGlyphsPositionInView() -> CGPoint {
            // Returns the XY offset of the range of glyphs from the view's origin
            var textOffset = CGPoint.zero

            if #available(iOS 16.0, tvOS 16.0, *), let tk2 = tk2LayoutManager as? NSTextLayoutManager {
                tk2.ensureLayout(for: tk2.documentRange)
                var maxY: CGFloat = 0
                tk2.enumerateTextLayoutFragments(from: tk2.documentRange.location, options: []) { fragment in
                    let bottom = fragment.layoutFragmentFrame.maxY
                    if bottom > maxY {
                        maxY = bottom
                    }
                    return true
                }
                let textHeight = ceil(maxY)
                if textHeight < self.bounds.size.height {
                    textOffset.y = (self.bounds.height - textHeight) / 2
                }
            } else {
                var textBounds = self.customLayoutManager.usedRect(for: self.customTextContainer)
                textBounds.size.width = ceil(textBounds.width)
                textBounds.size.height = ceil(textBounds.height)
                if textBounds.size.height < self.bounds.size.height {
                    let paddingHeight = (self.bounds.height - textBounds.size.height) / 2
                    textOffset.y = paddingHeight
                }
            }

            return textOffset
        }

        // MARK: - UI Responder Methods

        override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            if self.onTouch(touch) {
                return
            }
            super.touchesBegan(touches, with: event)
        }

        override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            if self.onTouch(touch) {
                return
            }
            super.touchesMoved(touches, with: event)
        }

        override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            _ = self.onTouch(touch)
            super.touchesCancelled(touches, with: event)
        }

        override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            if self.onTouch(touch) {
                return
            }
            super.touchesEnded(touches, with: event)
        }

        // MARK: - Private Methods

        private func displayActionController(forUrl url: URL) {
            var parentViewController: UIViewController?
            var parentResponder: UIResponder? = self
            while parentResponder != nil {
                parentResponder = parentResponder!.next
                if let viewController = parentResponder as? UIViewController {
                    parentViewController = viewController
                }
            }

            let actionController = UIAlertController(title: nil,
                                                     message: nil,
                                                     preferredStyle: .actionSheet)

            actionController.addAction(UIAlertAction(title: "Open",
                                                     style: .default,
                                                     handler: { _ in
                                                         if let delegate = self.delegate {
                                                             delegate.didSelect(url)
                                                         }
                                                     }))
            #if os(iOS) && !targetEnvironment(macCatalyst)
                if SSReadingList.supportsURL(url) {
                    actionController.addAction(UIAlertAction(title: "Add to Reading List",
                                                             style: .default,
                                                             handler: { _ in
                                                                 do {
                                                                     try SSReadingList.default()?.addItem(with: url,
                                                                                                          title: nil,
                                                                                                          previewText: nil)
                                                                 } catch {
                                                                     print("Error adding item to reading list.")
                                                                 }
                                                             }))
                }
                actionController.addAction(UIAlertAction(title: "Copy",
                                                         style: .default,
                                                         handler: { _ in
                                                             UIPasteboard.general.string = url.absoluteString
                                                         }))
                actionController.addAction(UIAlertAction(title: "Share...",
                                                         style: .default,
                                                         handler: { _ in
                                                             let activityViewController = UIActivityViewController(activityItems: [url],
                                                                                                                   applicationActivities: [])
                                                             if parentViewController != nil {
                                                                 activityViewController.dismiss(animated: true,
                                                                                                completion: nil)
                                                                 parentViewController?.present(activityViewController,
                                                                                               animated: true,
                                                                                               completion: nil)
                                                             }
                                                         }))
            #endif
            actionController.addAction(UIAlertAction(title: "Cancel",
                                                     style: .cancel,
                                                     handler: nil))

            if parentViewController != nil {
                parentViewController?.present(actionController,
                                              animated: true,
                                              completion: nil)
            }
        }

        private func onTouch(_ touch: UITouch) -> Bool {
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

        private func parseTextAndExtractURLRanges(_ attrString: NSAttributedString) {
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

        private func urlRange(at location: CGPoint) -> URLRange? {
            if #available(iOS 16.0, tvOS 16.0, *),
               let tk2Manager = tk2LayoutManager as? NSTextLayoutManager,
               let textStorage = tk2Manager.textContentManager as? NSTextContentStorage {
                urlRangeTK2(at: location, layoutManager: tk2Manager, storage: textStorage)
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
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
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

            let boundingRect = customLayoutManager.boundingRect(forGlyphRange: NSRange(location: 0,
                                                                                       length: customTextStorage.length),
                                                                in: customTextContainer)

            guard boundingRect.contains(location) else { return nil }

            let index = customLayoutManager.glyphIndex(for: location,
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
