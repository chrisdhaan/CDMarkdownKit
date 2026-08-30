//
//  CDMarkdownParser+Initialization.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 8/29/26.
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

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/// The common styling inputs shared by every default Markdown element. Bundled into one
/// type so the element-construction functions below stay under Swift's/SwiftLint's
/// parameter-count guidance.
struct CDMarkdownElementStyle {
    let font: CDFont
    let fontColor: CDColor
    let backgroundColor: CDColor
    let paragraphStyle: NSParagraphStyle
}

/// The full default set of Markdown elements a parser owns. A plain struct (rather than a
/// large tuple) so it isn't subject to SwiftLint's tuple-size guidance.
struct CDMarkdownElementSet {
    let table: CDMarkdownTable
    let horizontalRule: CDMarkdownHorizontalRule
    let header: CDMarkdownHeader
    let list: CDMarkdownList
    let orderedList: CDMarkdownOrderedList
    let taskList: CDMarkdownTaskList
    let quote: CDMarkdownQuote
    let link: CDMarkdownLink
    let automaticLink: CDMarkdownAutomaticLink
    let linkReference: CDMarkdownLinkReference
    let bold: CDMarkdownBold
    let italic: CDMarkdownItalic
    let code: CDMarkdownCode
    let syntax: CDMarkdownSyntax
    let strikethrough: CDMarkdownStrikethrough
}

private struct CDMarkdownBlockElements {
    let table: CDMarkdownTable
    let horizontalRule: CDMarkdownHorizontalRule
    let header: CDMarkdownHeader
    let quote: CDMarkdownQuote
}

private struct CDMarkdownListElements {
    let list: CDMarkdownList
    let orderedList: CDMarkdownOrderedList
    let taskList: CDMarkdownTaskList
}

private struct CDMarkdownLinkElements {
    let link: CDMarkdownLink
    let automaticLink: CDMarkdownAutomaticLink
    let linkReference: CDMarkdownLinkReference
}

private struct CDMarkdownInlineTextElements {
    let bold: CDMarkdownBold
    let italic: CDMarkdownItalic
    let code: CDMarkdownCode
    let syntax: CDMarkdownSyntax
}

extension CDMarkdownParser {

    static func makeDefaultParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 3
        paragraphStyle.paragraphSpacingBefore = 0
        paragraphStyle.lineSpacing = 1.38
        return paragraphStyle
    }

    /// Constructs the default set of Markdown elements shared by all of a parser's
    /// initializers. Factored out of `init(font:...)` purely to keep that initializer's
    /// own body short; behavior is unchanged.
    static func makeElements(style: CDMarkdownElementStyle,
                             boldFont: CDFont?,
                             italicFont: CDFont?) -> CDMarkdownElementSet {
        let block = makeBlockElements(style: style)
        let list = makeListElements(style: style)
        let link = makeLinkElements(style: style)
        let inlineText = makeInlineTextElements(style: style, boldFont: boldFont, italicFont: italicFont)
        let strikethrough = CDMarkdownStrikethrough(font: style.font,
                                                    color: style.fontColor,
                                                    backgroundColor: style.backgroundColor,
                                                    paragraphStyle: style.paragraphStyle)

        return CDMarkdownElementSet(table: block.table,
                                    horizontalRule: block.horizontalRule,
                                    header: block.header,
                                    list: list.list,
                                    orderedList: list.orderedList,
                                    taskList: list.taskList,
                                    quote: block.quote,
                                    link: link.link,
                                    automaticLink: link.automaticLink,
                                    linkReference: link.linkReference,
                                    bold: inlineText.bold,
                                    italic: inlineText.italic,
                                    code: inlineText.code,
                                    syntax: inlineText.syntax,
                                    strikethrough: strikethrough)
    }

    private static func makeBlockElements(style: CDMarkdownElementStyle) -> CDMarkdownBlockElements {
        CDMarkdownBlockElements(
            table: CDMarkdownTable(font: style.font,
                                   color: style.fontColor,
                                   backgroundColor: style.backgroundColor,
                                   paragraphStyle: style.paragraphStyle),
            horizontalRule: CDMarkdownHorizontalRule(font: style.font,
                                                     color: style.fontColor,
                                                     backgroundColor: style.backgroundColor,
                                                     paragraphStyle: style.paragraphStyle),
            header: CDMarkdownHeader(font: style.font,
                                     color: style.fontColor,
                                     backgroundColor: style.backgroundColor,
                                     paragraphStyle: style.paragraphStyle),
            quote: CDMarkdownQuote(font: style.font,
                                   color: style.fontColor,
                                   backgroundColor: style.backgroundColor,
                                   paragraphStyle: style.paragraphStyle)
        )
    }

    private static func makeListElements(style: CDMarkdownElementStyle) -> CDMarkdownListElements {
        CDMarkdownListElements(
            list: CDMarkdownList(font: style.font,
                                 color: style.fontColor,
                                 backgroundColor: style.backgroundColor,
                                 paragraphStyle: style.paragraphStyle),
            orderedList: CDMarkdownOrderedList(font: style.font,
                                               color: style.fontColor,
                                               backgroundColor: style.backgroundColor,
                                               paragraphStyle: style.paragraphStyle),
            taskList: CDMarkdownTaskList(font: style.font,
                                         color: style.fontColor,
                                         backgroundColor: style.backgroundColor,
                                         paragraphStyle: style.paragraphStyle)
        )
    }

    private static func makeLinkElements(style: CDMarkdownElementStyle) -> CDMarkdownLinkElements {
        CDMarkdownLinkElements(
            link: CDMarkdownLink(font: style.font,
                                 color: style.fontColor,
                                 backgroundColor: style.backgroundColor,
                                 paragraphStyle: style.paragraphStyle),
            automaticLink: CDMarkdownAutomaticLink(font: style.font,
                                                   color: style.fontColor,
                                                   backgroundColor: style.backgroundColor,
                                                   paragraphStyle: style.paragraphStyle),
            linkReference: CDMarkdownLinkReference(font: style.font,
                                                   color: style.fontColor,
                                                   backgroundColor: style.backgroundColor,
                                                   paragraphStyle: style.paragraphStyle)
        )
    }

    private static func makeInlineTextElements(style: CDMarkdownElementStyle,
                                               boldFont: CDFont?,
                                               italicFont: CDFont?) -> CDMarkdownInlineTextElements {
        CDMarkdownInlineTextElements(
            bold: CDMarkdownBold(font: style.font,
                                 customBoldFont: boldFont,
                                 color: style.fontColor,
                                 backgroundColor: style.backgroundColor,
                                 paragraphStyle: style.paragraphStyle),
            italic: CDMarkdownItalic(font: style.font,
                                     customItalicFont: italicFont,
                                     color: style.fontColor,
                                     backgroundColor: style.backgroundColor,
                                     paragraphStyle: style.paragraphStyle),
            code: CDMarkdownCode(font: style.font,
                                 color: style.fontColor,
                                 backgroundColor: style.backgroundColor,
                                 paragraphStyle: style.paragraphStyle),
            syntax: CDMarkdownSyntax(font: style.font,
                                     color: style.fontColor,
                                     backgroundColor: style.backgroundColor,
                                     paragraphStyle: style.paragraphStyle)
        )
    }

    /// Creates a parser pre-styled with the provided theme.
    /// Individual element properties can still be overridden after calling this initializer.
    public convenience init(theme: CDMarkdownTheme) {
        self.init(font: theme.font,
                  fontColor: theme.fontColor,
                  backgroundColor: theme.backgroundColor)

        applyHeaderAndTextTheme(theme)
        applyBlockTheme(theme)
        applyListAndLinkTheme(theme)
    }

    private func applyHeaderAndTextTheme(_ theme: CDMarkdownTheme) {
        self.header.font = theme.header.font ?? self.header.font
        self.header.color = theme.header.color ?? self.header.color
        self.header.fontIncrease = theme.header.fontIncrease
        self.header.paragraphStyle = theme.header.paragraphStyle ?? self.header.paragraphStyle
        self.header.underlineColor = theme.header.underlineColor
        self.header.underlineStyle = theme.header.underlineStyle

        self.bold.font = theme.bold.font ?? self.bold.font
        self.bold.color = theme.bold.color ?? self.bold.color
        self.bold.backgroundColor = theme.bold.backgroundColor
        self.bold.paragraphStyle = theme.bold.paragraphStyle
        self.bold.underlineColor = theme.bold.underlineColor
        self.bold.underlineStyle = theme.bold.underlineStyle

        self.italic.font = theme.italic.font ?? self.italic.font
        self.italic.color = theme.italic.color ?? self.italic.color
        self.italic.backgroundColor = theme.italic.backgroundColor
        self.italic.paragraphStyle = theme.italic.paragraphStyle
        self.italic.underlineColor = theme.italic.underlineColor
        self.italic.underlineStyle = theme.italic.underlineStyle

        self.code.font = theme.code.font ?? self.code.font
        self.code.color = theme.code.color ?? self.code.color
        self.code.backgroundColor = theme.code.backgroundColor ?? self.code.backgroundColor
        self.code.paragraphStyle = theme.code.paragraphStyle
        self.code.underlineColor = theme.code.underlineColor
        self.code.underlineStyle = theme.code.underlineStyle
    }

    private func applyBlockTheme(_ theme: CDMarkdownTheme) {
        self.syntax.font = theme.syntax.font ?? self.syntax.font
        self.syntax.color = theme.syntax.color ?? self.syntax.color
        self.syntax.backgroundColor = theme.syntax.backgroundColor ?? self.syntax.backgroundColor
        self.syntax.paragraphStyle = theme.syntax.paragraphStyle
        self.syntax.underlineColor = theme.syntax.underlineColor
        self.syntax.underlineStyle = theme.syntax.underlineStyle

        self.strikethrough.font = theme.strikethrough.font ?? self.strikethrough.font
        self.strikethrough.color = theme.strikethrough.color ?? self.strikethrough.color
        self.strikethrough.backgroundColor = theme.strikethrough.backgroundColor
        self.strikethrough.paragraphStyle = theme.strikethrough.paragraphStyle
        self.strikethrough.underlineColor = theme.strikethrough.underlineColor
        self.strikethrough.underlineStyle = theme.strikethrough.underlineStyle

        self.quote.font = theme.quote.font ?? self.quote.font
        self.quote.color = theme.quote.color ?? self.quote.color
        self.quote.backgroundColor = theme.quote.backgroundColor
        self.quote.paragraphStyle = theme.quote.paragraphStyle
        self.quote.underlineColor = theme.quote.underlineColor
        self.quote.underlineStyle = theme.quote.underlineStyle

        self.list.font = theme.list.font ?? self.list.font
        self.list.color = theme.list.color ?? self.list.color
        self.list.backgroundColor = theme.list.backgroundColor
        self.list.paragraphStyle = theme.list.paragraphStyle
        self.list.underlineColor = theme.list.underlineColor
        self.list.underlineStyle = theme.list.underlineStyle
    }

    private func applyListAndLinkTheme(_ theme: CDMarkdownTheme) {
        self.orderedList.font = theme.orderedList.font ?? self.orderedList.font
        self.orderedList.color = theme.orderedList.color ?? self.orderedList.color
        self.orderedList.backgroundColor = theme.orderedList.backgroundColor
        self.orderedList.paragraphStyle = theme.orderedList.paragraphStyle
        self.orderedList.underlineColor = theme.orderedList.underlineColor
        self.orderedList.underlineStyle = theme.orderedList.underlineStyle

        self.link.font = theme.link.font ?? self.link.font
        self.link.color = theme.link.color ?? self.link.color
        self.link.backgroundColor = theme.link.backgroundColor
        self.link.underlineColor = theme.link.underlineColor
        self.link.underlineStyle = theme.link.underlineStyle

        self.linkReference.font = theme.linkReference.font ?? self.linkReference.font
        self.linkReference.color = theme.linkReference.color ?? self.linkReference.color
        self.linkReference.backgroundColor = theme.linkReference.backgroundColor
        self.linkReference.underlineColor = theme.linkReference.underlineColor
        self.linkReference.underlineStyle = theme.linkReference.underlineStyle

        self.taskList.font = theme.taskList.font ?? self.taskList.font
        self.taskList.color = theme.taskList.color ?? self.taskList.color
        self.taskList.backgroundColor = theme.taskList.backgroundColor
        self.taskList.paragraphStyle = theme.taskList.paragraphStyle
        self.taskList.underlineColor = theme.taskList.underlineColor
        self.taskList.underlineStyle = theme.taskList.underlineStyle

        self.horizontalRule.font = theme.horizontalRule.font ?? self.horizontalRule.font
        self.horizontalRule.color = theme.horizontalRule.color ?? self.horizontalRule.color
        self.horizontalRule.backgroundColor = theme.horizontalRule.backgroundColor
        self.horizontalRule.paragraphStyle = theme.horizontalRule.paragraphStyle
        self.horizontalRule.underlineColor = theme.horizontalRule.underlineColor
        self.horizontalRule.underlineStyle = theme.horizontalRule.underlineStyle
    }
}
