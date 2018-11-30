//
//  CDMarkdownLevelElement.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
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

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

// MarkdownLevelElement serves the purpose of handling Elements which may have more than one
// representation (e.g. Headers or Lists)
public protocol CDMarkdownLevelElement: CDMarkdownElement, CDMarkdownStyle {

    // The maximum level of elements we should parse (e.g. limit the headers to 6 #s)
    var maxLevel: Int { get }

    func formatText(_ attributedString: NSMutableAttributedString,
                    range: NSRange,
                    level: Int)
    func addFullAttributes(_ attributedString: NSMutableAttributedString,
                           range: NSRange,
                           level: Int)
    func addAttributes(_ attributedString: NSMutableAttributedString,
                       range: NSRange,
                       level: Int)
    func attributesForLevel(_ level: Int) -> [CDAttributedStringKey: AnyObject]
}

public extension CDMarkdownLevelElement {

    func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    func addFullAttributes(_ attributedString: NSMutableAttributedString,
                           range: NSRange,
                           level: Int) {}

    func addAttributes(_ attributedString: NSMutableAttributedString,
                       range: NSRange,
                       level: Int) {
        attributedString.addAttributes(attributesForLevel(level - 1),
                                       range: range)
    }

    func attributesForLevel(_ level: Int) -> [CDAttributedStringKey: AnyObject] {
        return self.attributes
    }

    func match(_ match: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        let level = match.range(atIndex: 1).length
        addFullAttributes(attributedString,
                          range: match.range(atIndex: 0),
                          level: level)
        addAttributes(attributedString,
                      range: match.range(atIndex: 2),
                      level: level)
        let range = NSRange(location: match.range(atIndex: 1).location,
                            length: match.range(atIndex: 2).location - match.range(atIndex: 1).location)
        formatText(attributedString,
                   range: range,
                   level: level)
    }
}
