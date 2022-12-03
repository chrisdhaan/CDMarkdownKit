//
//  CodeLabelViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 6/11/18.
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

class CodeLabelViewController: BaseViewController {

    fileprivate var codeLabel: CDMarkdownLabel!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.onCustomParser = { [weak self] in
            // Configure label
            self?.codeLabel.roundAllCorners = true
        }

        self.onDefaultParser = { [weak self] in
            // Configure label
            self?.codeLabel.roundCodeCorners = true
            self?.codeLabel.roundSyntaxCorners = true
        }

        // Example initialization of CDMarkdownLabel
        let codeLabel = CDMarkdownLabel(frame: self.rect)
        codeLabel.delegate = self
        codeLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(codeLabel)
        self.codeLabel = codeLabel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.codeLabel.attributedText = self.configure()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Action Methods

    @IBAction private func clickedSegmentedControl(_: UISegmentedControl) {
        self.codeLabel.attributedText = self.configure()
    }
}

// MARK: - CDMarkdownLabelDelegate Methods

extension CodeLabelViewController: CDMarkdownLabelDelegate {

    func didSelect(_ url: URL) {
        UIApplication.shared.open(url,
                                  options: [:],
                                  completionHandler: nil)
    }
}
