//
//  CDMarkdownParser.swift
//  Pods
//
//  Created by Chris De Haan on 11/7/16.
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

open class CDMarkdownParser {
    
    // MARK: - Element Arrays
    fileprivate var escapingElements: [CDMarkdownElement]
    fileprivate var defaultElements: [CDMarkdownElement]
    fileprivate var unescapingElements: [CDMarkdownElement]
    
    open var customElements: [CDMarkdownElement]
    
    // MARK: - Basic Elements
    open let header: CDMarkdownHeader
    open let list: CDMarkdownList
    open let quote: CDMarkdownQuote
    open let link: CDMarkdownLink
    open let automaticLink: CDMarkdownAutomaticLink
    open let bold: CDMarkdownBold
    open let italic: CDMarkdownItalic
    open let code: CDMarkdownCode
    
    // MARK: - Escaping Elements
    fileprivate var codeEscaping = CDMarkdownCodeEscaping()
    fileprivate var escaping = CDMarkdownEscaping()
    fileprivate var unescaping = CDMarkdownUnescaping()
    
    // MARK: - Configuration
    // Enables or disables detection of URLs even without Markdown format
    open var automaticLinkDetectionEnabled: Bool = true
    open let font: UIFont
    open let fontColor: UIColor
    open let backgroundColor: UIColor
    
    // MARK: - Initializer
    public init(font: UIFont = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                fontColor: UIColor = UIColor.black,
                backgroundColor: UIColor = UIColor.clear,
                automaticLinkDetectionEnabled: Bool = true,
                customElements: [CDMarkdownElement] = []) {
        self.font = font
        self.fontColor = fontColor
        self.backgroundColor = backgroundColor
        
        header = CDMarkdownHeader(font: font)
        list = CDMarkdownList(font: font)
        quote = CDMarkdownQuote(font: font)
        link = CDMarkdownLink(font: font)
        automaticLink = CDMarkdownAutomaticLink(font: font)
        bold = CDMarkdownBold(font: font)
        italic = CDMarkdownItalic(font: font)
        code = CDMarkdownCode(font: font)
        
        self.automaticLinkDetectionEnabled = automaticLinkDetectionEnabled
        self.escapingElements = [codeEscaping, escaping]
        self.defaultElements = [header, list, quote, link, automaticLink, bold, italic]
        self.unescapingElements = [code, unescaping]
        self.customElements = customElements
    }
    
    // MARK: - Element Extensibility
    open func addCustomElement(_ element: CDMarkdownElement) {
        customElements.append(element)
    }
    
    open func removeCustomElement(_ element: CDMarkdownElement) {
        guard let index = customElements.index(where: { someElement -> Bool in
            return element === someElement
        }) else {
            return
        }
        customElements.remove(at: index)
    }
    
    // MARK: - Parsing
    open func parse(_ markdown: String) -> NSAttributedString {
        return parse(NSAttributedString(string: markdown))
    }
    
    open func parse(_ markdown: NSAttributedString) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: markdown)
        attributedString.addAttribute(NSFontAttributeName, value: font,
                                      range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSForegroundColorAttributeName, value: fontColor,
                                      range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSBackgroundColorAttributeName, value: backgroundColor,
                                      range: NSRange(location: 0, length: attributedString.length))
        var elements: [CDMarkdownElement] = escapingElements
        elements.append(contentsOf: defaultElements)
        elements.append(contentsOf: customElements)
        elements.append(contentsOf: unescapingElements)
        elements.forEach { element in
            if automaticLinkDetectionEnabled || type(of: element) != CDMarkdownAutomaticLink.self {
                element.parse(attributedString)
            }
        }
        return attributedString
    }
}
