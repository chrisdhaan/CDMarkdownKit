//
//  ViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 8/2/17.
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

import CDMarkdownKit
import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var storyboardTextView: CDMarkdownTextView!
    @IBOutlet private weak var storyboardLabel: CDMarkdownLabel!
    
    private var codeLabel: CDMarkdownLabel!
    private var codeTextView: CDMarkdownTextView!
    private let customMarkdownParser = CDMarkdownParser(fontColor: UIColor.brown,
                                                        backgroundColor: UIColor.yellow)
    private let defaultMarkdownParser = CDMarkdownParser()
    private let markdownString = NSLocalizedString("Markdown",
                                                   tableName: nil,
                                                   bundle: Bundle.main,
                                                   value: "",
                                                   comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let screenSize = UIScreen.main.bounds.size
        let rect = CGRect(x: 10,
                          y: self.segmentedControl.frame.maxY + 8,
                          width: CGFloat(screenSize.width - 20),
                          height: CGFloat(screenSize.height - (self.segmentedControl.frame.maxY + 23)))
        
        let textContainer = NSTextContainer(size: screenSize)
        let layoutManager = CDMarkdownLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        // Example initialization of CDMarkdownTextView
        let codeTextView = CDMarkdownTextView(frame: rect,
                                              textContainer: textContainer,
                                              layoutManager: layoutManager)
        codeTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        codeTextView.roundCodeCorners = true
        codeTextView.roundSyntaxCorners = true
        codeTextView.roundAllCorners = true
        self.view.addSubview(codeTextView)
        self.codeTextView = codeTextView
        
        // Example initialization of CDMarkdownLabel
        let codeLabel = CDMarkdownLabel(frame: rect)
        codeLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        codeLabel.roundCodeCorners = true
        codeLabel.roundSyntaxCorners = true
        codeLabel.roundAllCorners = true
        self.view.addSubview(codeLabel)
        self.codeLabel = codeLabel
        
        // Example of a markdown parser with custom properties
        self.customMarkdownParser.bold.color = UIColor.cyan
        self.customMarkdownParser.bold.backgroundColor = UIColor.purple
        let boldParagraphStyle = NSMutableParagraphStyle()
        boldParagraphStyle.paragraphSpacing = 10
        boldParagraphStyle.paragraphSpacingBefore = 0
        boldParagraphStyle.lineSpacing = 10.38
        self.customMarkdownParser.bold.paragraphStyle = boldParagraphStyle
        self.customMarkdownParser.header.color = UIColor.black
        self.customMarkdownParser.header.backgroundColor = UIColor.orange
        self.customMarkdownParser.list.color = UIColor.black
        self.customMarkdownParser.list.backgroundColor = UIColor.red
        let listParagraphStyle = NSMutableParagraphStyle()
        listParagraphStyle.paragraphSpacing = 15
        listParagraphStyle.paragraphSpacingBefore = 0
        listParagraphStyle.lineSpacing = 15.38
        self.customMarkdownParser.list.paragraphStyle = listParagraphStyle
        self.customMarkdownParser.quote.color = UIColor.gray
        self.customMarkdownParser.quote.backgroundColor = UIColor.clear
        self.customMarkdownParser.link.color = UIColor.blue
        self.customMarkdownParser.link.backgroundColor = UIColor.green
        let linkParagraphStyle = NSMutableParagraphStyle()
        linkParagraphStyle.paragraphSpacing = 20
        linkParagraphStyle.paragraphSpacingBefore = 0
        linkParagraphStyle.lineSpacing = 20.38
        self.customMarkdownParser.link.paragraphStyle = linkParagraphStyle
        self.customMarkdownParser.automaticLink.color = UIColor.blue
        self.customMarkdownParser.automaticLink.backgroundColor = UIColor.green
        self.customMarkdownParser.italic.color = UIColor.gray
        self.customMarkdownParser.italic.backgroundColor = UIColor.clear
        self.customMarkdownParser.code.font = UIFont.systemFont(ofSize: 17)
        self.customMarkdownParser.code.color = UIColor.red
        self.customMarkdownParser.code.backgroundColor = UIColor.black
        self.customMarkdownParser.syntax.font = UIFont.systemFont(ofSize: 15)
        self.customMarkdownParser.syntax.color = UIColor.lightGray
        self.customMarkdownParser.syntax.backgroundColor = UIColor.black
        self.customMarkdownParser.image.size = CGSize(width: 100,
                                                      height: 50)
        
        self.configure()
        
        // Set isHidden to false on one element to view markdown in
        self.storyboardTextView.isHidden = false
        self.storyboardLabel.isHidden = true
        self.codeTextView.isHidden = true
        self.codeLabel.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction private func clickedSegmentedControl(_: UISegmentedControl) {
        self.configure()
    }
    
    private func configure() {
        let attributedString = NSAttributedString(string: self.markdownString)
        // Determine whether to show default or custom parsing
        var attributedText = NSAttributedString(string: "")
        if self.segmentedControl.selectedSegmentIndex == 0 {
            // Configure storyboard text view
            self.storyboardTextView.roundCodeCorners = true
            self.storyboardTextView.roundSyntaxCorners = true
            codeTextView.roundCodeCorners = true
            codeTextView.roundSyntaxCorners = true
            // Configure storyboard label
            self.storyboardLabel.roundCodeCorners = true
            self.storyboardLabel.roundSyntaxCorners = true
            codeLabel.roundCodeCorners = true
            codeLabel.roundSyntaxCorners = true
            // Parse markdown
            attributedText = self.defaultMarkdownParser.parse(attributedString)
        } else {
            // Configure text view
            self.storyboardTextView.roundAllCorners = true
            codeTextView.roundAllCorners = true
            // Configure label
            self.storyboardLabel.roundAllCorners = true
            codeLabel.roundAllCorners = true
            // Parse markdown
            attributedText = self.customMarkdownParser.parse(attributedString)
        }
        
        self.storyboardTextView.attributedText = attributedText
        self.storyboardLabel.attributedText = attributedText
        self.codeTextView.attributedText = attributedText
        self.codeLabel.attributedText = attributedText
    }
}

