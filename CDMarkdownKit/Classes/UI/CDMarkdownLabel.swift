//
//  CDMarkdownLabel.swift
//  CDMarkdownKit
//
//  Created by Chris De Haan on 12/14/16.
//
//  Copyright (c) 2016 Christopher de Haan <contact@christopherdehaan.me>
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

import UIKit

open class CDMarkdownLabel: UILabel {

    open var customLayoutManager: CDMarkdownLayoutManager!
    open var customTextContainer: NSTextContainer!
    open var customTextStorage: NSTextStorage!
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
            if let _ = self.customTextContainer,
                let layoutManager = self.customLayoutManager {
                self.customTextStorage = NSTextStorage(attributedString: newValue)
                self.customTextStorage.addLayoutManager(layoutManager)
                layoutManager.textStorage = self.customTextStorage
            }
            self.setNeedsDisplay()
        }
    }
    
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
    open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
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
        self.customLayoutManager.drawBackground(forGlyphRange: glyphRange, at: glyphsPosition)
        self.customLayoutManager.drawGlyphs(forGlyphRange: glyphRange, at: glyphsPosition)
    }
    
    fileprivate func calculateGlyphsPositionInView() -> CGPoint {
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
}

// MARK: - LayoutManager Delegate
extension CDMarkdownLabel: NSLayoutManagerDelegate {
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        var range = NSRange()
        // Don't allow line breaks on URL's
        let linkURL = layoutManager.textStorage?.attribute(NSLinkAttributeName, at: charIndex, effectiveRange: &range)
        
        return !((linkURL != nil) && (charIndex > range.location) && (charIndex <= NSMaxRange(range)))
    }
}
