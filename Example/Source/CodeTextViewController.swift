//
//  CodeTextViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 8/2/17.
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

import CDMarkdownKit
import UIKit

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
            self?.codeTextView.roundAllCorners = true
        }

        // Example initialization of CDMarkdownTextView via the preferred factory
        let codeTextView = CDMarkdownTextView.makeTextView(frame: self.rect)
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(codeTextView)

        NSLayoutConstraint.activate([
            codeTextView.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 8),
            codeTextView.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            codeTextView.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            codeTextView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        self.codeTextView = codeTextView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task { [weak self] in
            guard let self else { return }
            self.codeTextView.attributedText = await self.configure()
        }
    }

    // MARK: - Action Methods

    @IBAction private func clickedSegmentedControl(_: UISegmentedControl) {
        Task { [weak self] in
            guard let self else { return }
            self.codeTextView.attributedText = await self.configure()
        }
    }
}
