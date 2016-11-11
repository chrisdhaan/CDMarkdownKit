//
//  ViewController.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/07/2016.
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

import CDMarkdownKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let markdownString = NSLocalizedString("Markdown", tableName: nil, bundle: Bundle.main, value: "", comment: "")
        let attributedString = NSAttributedString(string: markdownString)
        
        // Example of a markdown parser with default properties
        let markdownParser = CDMarkdownParser()
        
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

        self.textView.attributedText = markdownParser.parse(attributedString)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

