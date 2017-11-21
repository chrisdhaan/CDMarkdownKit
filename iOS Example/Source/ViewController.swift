//
//  ViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 8/2/17.
//
//  Copyright (c) 2016-2017 Christopher de Haan <contact@christopherdehaan.me>
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

    @IBOutlet fileprivate weak var textView: CDMarkdownTextView!
    @IBOutlet fileprivate weak var label: CDMarkdownLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let markdownString = NSLocalizedString("Markdown3", tableName: nil, bundle: Bundle.main, value: "", comment: "")
        let attributedString = NSAttributedString(string: markdownString)
        
        // Example of a markdown parser with default properties
        let markdownParser = CDMarkdownParser()
        // Configure text view
        self.textView.roundCodeCorners = true
        self.textView.roundSyntaxCorners = true
        // Configure label
        self.label.roundCodeCorners = true
        self.label.roundSyntaxCorners = true
        
        // Example of a markdown parser with custom properties
//        let markdownParser = CDMarkdownParser(fontColor: UIColor.brown, backgroundColor: UIColor.yellow)
//        markdownParser.bold.color = UIColor.cyan
//        markdownParser.bold.backgroundColor = UIColor.purple
//        markdownParser.header.color = UIColor.black
//        markdownParser.header.backgroundColor = UIColor.orange
//        markdownParser.list.color = UIColor.black
//        markdownParser.list.backgroundColor = UIColor.red
//        markdownParser.quote.color = UIColor.gray
//        markdownParser.quote.backgroundColor = UIColor.clear
//        markdownParser.link.color = UIColor.blue
//        markdownParser.link.backgroundColor = UIColor.green
//        markdownParser.automaticLink.color = UIColor.blue
//        markdownParser.automaticLink.backgroundColor = UIColor.green
//        markdownParser.italic.color = UIColor.gray
//        markdownParser.italic.backgroundColor = UIColor.clear
//        markdownParser.code.font = UIFont.systemFont(ofSize: 17)
//        markdownParser.code.color = UIColor.red
//        markdownParser.code.backgroundColor = UIColor.black
//        markdownParser.syntax.font = UIFont.systemFont(ofSize: 15)
//        markdownParser.syntax.color = UIColor.lightGray
//        markdownParser.syntax.backgroundColor = UIColor.black
        // Configure text view
//        self.textView.roundAllCorners = true
        // Configure label
//        self.label.roundAllCorners = true
        
        let attributedText = markdownParser.parse(attributedString)
        self.textView.attributedText = attributedText
        self.textView.isHidden = false
        self.label.attributedText = attributedText
        self.label.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

