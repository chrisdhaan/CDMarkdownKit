//
//  ViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 8/2/17.
//
//  Copyright © 2016-2022 Christopher de Haan <contact@christopherdehaan.me>
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

import CDMarkdownKit
import UIKit

public typealias CDLayoutConstraintAttribute = NSLayoutConstraint.Attribute
public typealias CDLayoutConstraintRelation = NSLayoutConstraint.Relation

class CodeTextViewController: BaseViewController {

    fileprivate var codeTextView: CDMarkdownTextView!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.onCustomParser = { [weak self] in
            // Configure text view
            self?.codeTextView.roundAllCorners = true
        }

        self.onDefaultParser = { [weak self] in
            // Configure text view
            self?.codeTextView.roundCodeCorners = true
            self?.codeTextView.roundSyntaxCorners = true
        }

        // Initialize textContainer and layoutManager for CDMarkdownTextView
        let textContainer = NSTextContainer(size: self.rect.size)
        let layoutManager = CDMarkdownLayoutManager()
        layoutManager.addTextContainer(textContainer)

        // Example initialization of CDMarkdownTextView
        let codeTextView = CDMarkdownTextView(frame: self.rect,
                                              textContainer: textContainer,
                                              layoutManager: layoutManager)
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(codeTextView)

        // Add constraints so intrinsic content size is set correctly
        let topConstraint = NSLayoutConstraint(item: codeTextView,
                                               attribute: CDLayoutConstraintAttribute.top,
                                               relatedBy: CDLayoutConstraintRelation.equal,
                                               toItem: self.segmentedControl,
                                               attribute: CDLayoutConstraintAttribute.bottom,
                                               multiplier: 1,
                                               constant: 8)
        let leadingConstraint = NSLayoutConstraint(item: codeTextView,
                                                   attribute: CDLayoutConstraintAttribute.leading,
                                                   relatedBy: CDLayoutConstraintRelation.equal,
                                                   toItem: codeTextView.superview,
                                                   attribute: CDLayoutConstraintAttribute.leadingMargin,
                                                   multiplier: 1,
                                                   constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: codeTextView,
                                                    attribute: CDLayoutConstraintAttribute.trailing,
                                                    relatedBy: CDLayoutConstraintRelation.equal,
                                                    toItem: codeTextView.superview,
                                                    attribute: CDLayoutConstraintAttribute.trailingMargin,
                                                    multiplier: 1,
                                                    constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.bottomLayoutGuide,
                                                  attribute: CDLayoutConstraintAttribute.top,
                                                  relatedBy: CDLayoutConstraintRelation.equal,
                                                  toItem: codeTextView,
                                                  attribute: CDLayoutConstraintAttribute.bottom,
                                                  multiplier: 1,
                                                  constant: 20)
        self.view.addConstraints([topConstraint,
                                  leadingConstraint,
                                  trailingConstraint,
                                  bottomConstraint])

        self.codeTextView = codeTextView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.codeTextView.attributedText = self.configure()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Action Methods

    @IBAction private func clickedSegmentedControl(_: UISegmentedControl) {
        self.codeTextView.attributedText = self.configure()
    }
}
