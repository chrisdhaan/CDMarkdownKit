//
//  CDMarkdownLabel.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 12/14/16.
//
//  Copyright © 2016-2018 Christopher de Haan <contact@christopherdehaan.me>
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

#if os(iOS) || os(tvOS)

import UIKit

public protocol CDMarkdownLabelDelegate: class {
    func didSelect(_ url: URL)
}

typealias URLRange = (url: URL, range: NSRange)

open class CDMarkdownLabel: UILabel {

    open var customLayoutManager: CDMarkdownLayoutManager!
    open var customTextContainer: NSTextContainer!
    open var customTextStorage: NSTextStorage!
    open weak var delegate: CDMarkdownLabelDelegate?
    open var roundAllCorners: Bool = false {
        didSet {
            if let layoutManager = self.customLayoutManager {
                layoutManager.roundAllCorners = roundAllCorners
            }
        }
    }
    open var roundCodeCorners: Bool = false {
        didSet {
            if let layoutManager = self.customLayoutManager {
                layoutManager.roundCodeCorners = roundCodeCorners
            }
        }
    }
    open var roundSyntaxCorners: Bool = false {
        didSet {
            if let layoutManager = self.customLayoutManager {
                layoutManager.roundSyntaxCorners = roundSyntaxCorners
            }
        }
    }

    open override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            if let textContainer = self.customTextContainer {
                textContainer.size = self.bounds.size
            }
        }
    }
    open override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            if let textContainer = self.customTextContainer {
                textContainer.size = self.bounds.size
            }
        }
    }
    open override var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }
        set {
            if self.customTextContainer != nil,
                let layoutManager = self.customLayoutManager {
                self.parseTextAndExtractURLRanges(newValue)
                self.customTextStorage = NSTextStorage(attributedString: newValue)
                self.customTextStorage.addLayoutManager(layoutManager)
                layoutManager.textStorage = self.customTextStorage
            }
            self.setNeedsDisplay()
        }
    }

    private var selectedURLRange: URLRange?
    private lazy var urlRanges = [URLRange]()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        self.customTextContainer.size = self.bounds.size
    }

    open func configure() {
        self.isUserInteractionEnabled = true

        self.customLayoutManager = CDMarkdownLayoutManager()

        if let textContainer = self.customTextContainer {
            self.customLayoutManager.addTextContainer(textContainer)
        } else {
            self.customTextContainer = NSTextContainer()
            self.customTextContainer.lineFragmentPadding = 0
            self.customTextContainer.maximumNumberOfLines = self.numberOfLines
            self.customTextContainer.lineBreakMode = self.lineBreakMode
            self.customTextContainer.size = self.frame.size

            self.customLayoutManager.addTextContainer(self.customTextContainer)
        }
    }

    // MARK: - Layout And Rendering

    open override func textRect(forBounds bounds: CGRect,
                                limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        // Use our text container to calculate the bounds required. First save our
        // current text container setup
        let savedTextContainerSize = self.customTextContainer.size
        let savedTextContainerNumberOfLines = self.customTextContainer.maximumNumberOfLines
        // Apply the new potential bounds and number of lines
        self.customTextContainer.size = self.bounds.size
        self.customTextContainer.maximumNumberOfLines = numberOfLines
        // Measure the text with the new state
        var textBounds = self.customLayoutManager.usedRect(for: self.customTextContainer)
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

    open override func drawText(in rect: CGRect) {
        // Calculate the offset of the text in the view
        let glyphRange = self.customLayoutManager.glyphRange(for: self.customTextContainer)
        let glyphsPosition = self.calculateGlyphsPositionInView()
        // Drawing code
        self.customLayoutManager.drawBackground(forGlyphRange: glyphRange,
                                                at: glyphsPosition)
        self.customLayoutManager.drawGlyphs(forGlyphRange: glyphRange,
                                            at: glyphsPosition)
    }

    private func calculateGlyphsPositionInView() -> CGPoint {
        // Returns the XY offset of the range of glyphs from the view's origin
        var textOffset = CGPoint.zero

        var textBounds = self.customLayoutManager.usedRect(for: self.customTextContainer)

        textBounds.size.width = ceil(textBounds.width)
        textBounds.size.height = ceil(textBounds.height)

        if textBounds.size.height < self.bounds.size.height {
            let paddingHeight = (self.bounds.height - textBounds.size.height) / 2
            textOffset.y = paddingHeight
        }

        return textOffset
    }

    // MARK: - UI Responder Methods

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if self.onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if self.onTouch(touch) { return }
        super.touchesMoved(touches, with: event)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = self.onTouch(touch)
        super.touchesCancelled(touches, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if self.onTouch(touch) { return }
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
#if os(iOS)
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
                if urlRange.range.location != self.selectedURLRange?.range.location || urlRange.range.length != self.selectedURLRange?.range.length {
                    self.selectedURLRange = urlRange
                }
                avoidSuperCall = true
            } else {
                self.selectedURLRange = nil
            }
        case .ended:
            guard let selectedRange = self.selectedURLRange else { return avoidSuperCall }

            self.displayActionController(forUrl: selectedRange.url)

            let when = DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.selectedURLRange = nil
            }
            avoidSuperCall = true
        case .cancelled:
            self.selectedURLRange = nil
        case .stationary:
            break
        }

        return avoidSuperCall
    }

    private func parseTextAndExtractURLRanges(_ attrString: NSAttributedString) {

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
        guard self.customTextStorage.length > 0 else { return nil }

        let correctLocation = location
        let boundingRect = customLayoutManager.boundingRect(forGlyphRange: NSRange(location: 0,
                                                                                   length: self.customTextStorage.length),
                                                            in: self.customTextContainer)

        guard boundingRect.contains(correctLocation) else { return nil }

        let index = self.customLayoutManager.glyphIndex(for: correctLocation,
                                                        in: self.customTextContainer)

        for urlRange in urlRanges {
            if index >= urlRange.range.location && index <= urlRange.range.location + urlRange.range.length {
                return urlRange
            }
        }

        return nil
    }
}

// MARK: - LayoutManagerDelegate Methods

extension CDMarkdownLabel: NSLayoutManagerDelegate {
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
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

#endif
