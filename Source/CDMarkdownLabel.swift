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

        /// Bundles the three objects that make up the TextKit 2 stack, so every dispatch site
        /// checks one thing instead of independently downcasting whichever of the three it
        /// happens to need — the previous split let the objects drift out of sync with each
        /// other. Internal (not `private`) so tests can inspect its fields via `@testable import`.
        @available(iOS 16.0, tvOS 16.0, *)
        internal struct TK2Stack {
            let contentStorage: NSTextContentStorage
            let layoutManager: NSTextLayoutManager
            let delegate: CDMarkdownTextLayoutDelegate
        }

        /// Holds a `TK2Stack` on iOS/tvOS 16+. Type-erased to `Any?` so the property can exist
        /// unconditionally (the stack type itself is `@available`). Internal (not `private`) so
        /// tests can inspect and force TextKit 2 wiring via `@testable import`.
        internal var tk2Stack: Any?

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
                   let stack = tk2Stack as? TK2Stack {
                    stack.delegate.roundAllCorners = roundAllCorners
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
                super.attributedText = newValue
                guard let newValue else {
                    urlRanges.removeAll()
                    if #available(iOS 16.0, tvOS 16.0, *),
                       let stack = tk2Stack as? TK2Stack {
                        stack.contentStorage.textStorage?.setAttributedString(NSAttributedString())
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
                   let stack = tk2Stack as? TK2Stack {
                    if let textStorage = stack.contentStorage.textStorage {
                        textStorage.setAttributedString(newValue)
                    } else {
                        let textStorage = NSTextStorage(attributedString: newValue)
                        stack.contentStorage.textStorage = textStorage
                    }
                } else if customTextContainer != nil,
                          let layoutManager = customLayoutManager {
                    customTextStorage = NSTextStorage(attributedString: newValue)
                    customTextStorage.addLayoutManager(layoutManager)
                }

                #if os(iOS) || os(visionOS)
                    if let parser = markdownParser {
                        self.accessibilityAttributedLabel = parser.accessibilityAttributedString(from: newValue)
                    }
                #endif

                setNeedsDisplay()
            }
        }

        /// Not private: `onTouch` reads/writes this from CDMarkdownLabel+LinkInteraction.swift.
        internal var selectedURLRange: URLRange?
        /// Internal (not `private`) so tests can assert on extracted link ranges via `@testable import`.
        internal lazy var urlRanges = [URLRange]()

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
            if #available(iOS 16.0, tvOS 16.0, *), let tk2 = (tk2Stack as? TK2Stack)?.layoutManager {
                tk2.ensureLayout(for: tk2.documentRange)
                textBounds = .zero
                enumerateTK2Fragments(tk2) { fragment in
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
               let stack = tk2Stack as? TK2Stack {
                drawTextTK2(in: rect, layoutManager: stack.layoutManager)
            } else {
                drawTextTK1(in: rect)
            }
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

    }

#endif
