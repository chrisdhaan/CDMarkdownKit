//
//  StoryboardTextViewController.swift
//  iOS Example
//
//  Created by Christopher de Haan on 6/11/18.
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

class StoryboardTextViewController: BaseViewController {

    @IBOutlet fileprivate weak var storyboardTextView: CDMarkdownTextView!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.onCustomParser = { [weak self] in
            // Configure text view
            self?.storyboardTextView.roundAllCorners = true
        }

        self.onDefaultParser = { [weak self] in
            // Configure text view
            self?.storyboardTextView.roundAllCorners = true
        }

        // Links are inert until isSelectable is enabled and a delegate handles taps
        self.storyboardTextView.isSelectable = true
        self.storyboardTextView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task { [weak self] in
            guard let self else { return }
            self.storyboardTextView.attributedText = await self.configure()
        }
    }

    // MARK: - Action Methods

    @IBAction private func clickedSegmentedControl(_: UISegmentedControl) {
        Task { [weak self] in
            guard let self else { return }
            self.storyboardTextView.attributedText = await self.configure()
        }
    }
}

// MARK: - UITextViewDelegate Methods

extension StoryboardTextViewController: UITextViewDelegate {

    func textView(_: UITextView,
                  shouldInteractWith url: URL,
                  in _: NSRange,
                  interaction _: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(url,
                                  options: [:],
                                  completionHandler: nil)
        return false
    }
}
