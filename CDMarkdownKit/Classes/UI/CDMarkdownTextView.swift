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

    fileprivate var customLayoutManager: CDMarkdownLayoutManager!
    
    open var roundAllCorners: Bool! {
        get {
            if let roundAllCorners = roundAllCorners {
                return roundAllCorners
            } else {
                return false
            }
        }
        set {
            self.customLayoutManager.roundAllCorners = newValue
        }
    }
    open var roundCodeCorners: Bool! {
        get {
            if let roundCodeCorners = roundCodeCorners {
                return roundCodeCorners
            } else {
                return false
            }
        }
        set {
            self.customLayoutManager.roundCodeCorners = newValue
        }
    }
    open var roundSyntaxCorners: Bool! {
        get {
            if let roundSyntaxCorners = roundSyntaxCorners {
                return roundSyntaxCorners
            } else {
                return false
            }
        }
        set {
            self.customLayoutManager.roundSyntaxCorners = newValue
        }
    }
    
    open override var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }
        set {
            self.textStorage.setAttributedString(newValue)
        }
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    open func configure() {
        let layoutManager = CDMarkdownLayoutManager()
        layoutManager.roundAllCorners = false
        layoutManager.roundCodeCorners = false
        layoutManager.roundSyntaxCorners = false
        layoutManager.addTextContainer(self.textContainer)
        self.textStorage.addLayoutManager(layoutManager)
        self.customLayoutManager = layoutManager
    }
}
