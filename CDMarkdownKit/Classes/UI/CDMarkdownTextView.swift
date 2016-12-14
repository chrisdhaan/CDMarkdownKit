//
//  CDMarkdownTextView.swift
//  Pods
//
//  Created by Chris De Haan on 12/8/16.
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

open class CDMarkdownTextView: UITextView {
    
    open var customLayoutManager: CDMarkdownLayoutManager!
    open var customTextStorage: NSTextStorage!
    open var roundAllCorners: Bool = false {
        didSet {
            self.customLayoutManager.roundAllCorners = roundAllCorners
        }
    }
    open var roundCodeCorners: Bool = false {
        didSet {
            self.customLayoutManager.roundCodeCorners = roundCodeCorners
        }
    }
    open var roundSyntaxCorners: Bool = false {
        didSet {
            self.customLayoutManager.roundSyntaxCorners = roundSyntaxCorners
        }
    }
    
    open override var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }
        set {
            self.customTextStorage = NSTextStorage(attributedString: newValue)
            if let layoutManager = self.customLayoutManager {
                self.customTextStorage.addLayoutManager(layoutManager)
            } else {
                self.configure()
                
                self.customTextStorage.addLayoutManager(self.customLayoutManager)
            }
        }
    }
    
    public init(frame: CGRect, textContainer: NSTextContainer, layoutManager: CDMarkdownLayoutManager) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.customLayoutManager = layoutManager
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open func configure() {
        self.customLayoutManager = CDMarkdownLayoutManager()
        self.customLayoutManager.addTextContainer(self.textContainer)
        
        self.isScrollEnabled = true
        self.isSelectable = false
        self.isEditable = false
    }
}
