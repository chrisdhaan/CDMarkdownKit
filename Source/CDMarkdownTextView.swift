//
//  CDMarkdownTextView.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/8/16.
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

#if os(iOS) || os(tvOS) || os(visionOS)

    import UIKit

    /// A `UITextView` subclass that renders styled Markdown text with custom layout management.
    ///
    /// Use ``CDMarkdownTextView`` to display longer Markdown-formatted text with scrolling support.
    /// Set ``attributedText`` with an ``NSAttributedString`` produced by ``CDMarkdownParser`` to display parsed Markdown.
    /// Links are automatically detected and highlighted when ``automaticLinkDetectionEnabled`` is `true`.
    @MainActor
    open class CDMarkdownTextView: UITextView {

        /// The custom layout manager used for rendering with rounded-corner backgrounds and link detection.
        open var customLayoutManager: CDMarkdownLayoutManager!

        /// The custom text storage that holds the attributed text and layout information.
        open var customTextStorage: NSTextStorage!

        /// Holds a CDMarkdownTextLayoutDelegate on iOS/tvOS 16+. Internal (not `private`) so
        /// tests can inspect TextKit 2 wiring via `@testable import`.
        internal var tk2Delegate: Any?

        /// When `true`, all background color regions (code blocks, syntax blocks, etc.) are drawn with rounded corners.
        /// When `false` (default), backgrounds are drawn as rectangles. Set to `true` for a softer appearance.
        open var roundAllCorners: Bool = false {
            didSet {
                if #available(iOS 16.0, tvOS 16.0, *),
                   let delegate = tk2Delegate as? CDMarkdownTextLayoutDelegate {
                    delegate.roundAllCorners = roundAllCorners
                } else {
                    if let layoutManager = self.customLayoutManager {
                        layoutManager.roundAllCorners = roundAllCorners
                    }
                }
            }
        }

        override open var attributedText: NSAttributedString! {
            get {
                super.attributedText
            }
            set {
                super.attributedText = newValue
                guard let newValue else { return }
                if let layoutManager = self.customLayoutManager {
                    if !self.textStorage.layoutManagers.contains(where: { $0 === layoutManager }) {
                        // TextKit 1 fallback (iOS/tvOS 15): keep the custom layout manager
                        // attached to the view's real, visible text storage rather than
                        // creating a second, disconnected NSTextStorage that would silently
                        // detach it.
                        self.textStorage.setAttributedString(newValue)
                    }
                    // Populate on every assignment, matching CDMarkdownLabel/CDMarkdownNSTextView.
                    self.customTextStorage = self.textStorage
                }
            }
        }

        public init(frame: CGRect,
                    textContainer: NSTextContainer,
                    layoutManager: CDMarkdownLayoutManager) {
            super.init(frame: frame,
                       textContainer: textContainer)

            self.customLayoutManager = layoutManager
        }

        override public init(frame: CGRect,
                             textContainer: NSTextContainer?) {
            super.init(frame: frame,
                       textContainer: textContainer)
            self.configure()
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.configure()
        }

        /// Configures the text view's custom layout manager and text storage.
        ///
        /// Called automatically during initialization. On iOS 16+, this uses TextKit 2 with
        /// ``CDMarkdownTextLayoutDelegate``. On iOS 15, this uses TextKit 1 with ``CDMarkdownLayoutManager``.
        open func configure() {
            if #available(iOS 16.0, tvOS 16.0, *) {
                configureTK2()
            } else {
                configureTK1()
            }
            isScrollEnabled = true
            isSelectable = false
            #if os(iOS)
                isEditable = false
            #endif
        }

        /// Configures TextKit 2 rendering (iOS 16+). Internal (not `private`) so tests can
        /// force this path deterministically via `@testable import`.
        @available(iOS 16.0, tvOS 16.0, *)
        internal func configureTK2() {
            guard let layoutManager = textLayoutManager else {
                configureTK1()
                return
            }
            let delegate = CDMarkdownTextLayoutDelegate()
            delegate.layoutManager = layoutManager
            layoutManager.delegate = delegate
            tk2Delegate = delegate
        }

        /// Configures TextKit 1 rendering (iOS 15). Internal (not `private`) so tests can
        /// force this path deterministically via `@testable import` — every CI/local
        /// simulator is iOS 16+, so `#available` alone can never select this branch in a test.
        internal func configureTK1() {
            textStorage.removeLayoutManager(layoutManager)
            customLayoutManager = CDMarkdownLayoutManager()
            textStorage.addLayoutManager(customLayoutManager)
            customLayoutManager.addTextContainer(textContainer)
        }

        /// Preferred factory for programmatic construction.
        /// On iOS/tvOS 16+, the system defaults to TextKit 2 when no text container is provided.
        @MainActor
        public static func makeTextView(frame: CGRect) -> CDMarkdownTextView {
            CDMarkdownTextView(frame: frame, textContainer: nil)
        }
    }

#endif
