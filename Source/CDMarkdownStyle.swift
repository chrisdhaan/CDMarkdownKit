//
//  CDMarkdownStyle.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haan on 11/7/16.
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

/// Protocol defining the styling attributes for Markdown elements.
///
/// Conform to this protocol (usually via ``CDMarkdownCommonElement``, ``CDMarkdownLevelElement``,
/// or ``CDMarkdownLinkElement``) to define how an element's parsed text should be styled.
/// Return `nil` for any property you don't want to customize — the default values from
/// ``CDMarkdownParser`` will apply instead.
///
/// The ``attributes`` property computes the final `NSAttributedString` attribute dictionary
/// from your style properties.
public protocol CDMarkdownStyle: Sendable {

    /// The font to apply to this element. Return `nil` to use the parser's default font.
    var font: CDFont? { get }

    /// The foreground text color for this element. Return `nil` to use the parser's default color.
    var color: CDColor? { get }

    /// The background color for this element. Return `nil` to use the parser's default background.
    var backgroundColor: CDColor? { get }

    /// The paragraph style (spacing, alignment, line height, etc.) for this element.
    /// Return `nil` to use the parser's default paragraph style.
    var paragraphStyle: NSParagraphStyle? { get }

    /// The underline color to apply to this element. Return `nil` for no custom underline color.
    var underlineColor: CDColor? { get }

    /// The underline style (single line, double line, etc.) to apply to this element.
    /// Return `nil` for no underline. See `NSUnderlineStyle` for available styles.
    var underlineStyle: NSUnderlineStyle? { get }

    /// The strikethrough color to apply to this element. Return `nil` for no custom strikethrough color.
    var strikethroughColor: CDColor? { get }

    /// The strikethrough style to apply to this element. Return `nil` for no strikethrough.
    /// See `NSUnderlineStyle` for available styles (single, double, etc.).
    var strikethroughStyle: NSUnderlineStyle? { get }

    /// The computed dictionary of `NSAttributedString` attributes for this style.
    ///
    /// This property builds the final attributes dictionary from the style properties.
    /// The default implementation assembles attributes from all non-nil properties and
    /// uses the ``CDAttributedStringKey`` type aliases.
    var attributes: [CDAttributedStringKey: AnyObject] { get }
}

public extension CDMarkdownStyle {

    var strikethroughColor: CDColor? { return nil }
    var strikethroughStyle: NSUnderlineStyle? { return nil }

    var attributes: [CDAttributedStringKey: AnyObject] {
        var attributes = [CDAttributedStringKey: AnyObject]()

        if let font = font {
            attributes.addFont(font)
        }
        if let color = color {
            attributes.addForegroundColor(color)
        }
        if let backgroundColor = backgroundColor {
            attributes.addBackgroundColor(backgroundColor)
        }
        if let paragraphStyle = paragraphStyle {
            attributes.addParagraphStyle(paragraphStyle)
        }
        if let underlineColor = underlineColor {
            attributes.addUnderlineColor(underlineColor)
        }
        if let underlineStyle = underlineStyle {
            attributes.addUnderlineStyle(underlineStyle)
        }
        if let strikethroughColor = strikethroughColor {
            attributes.addStrikethroughColor(strikethroughColor)
        }
        if let strikethroughStyle = strikethroughStyle {
            attributes.addStrikethroughStyle(strikethroughStyle)
        }

        return attributes
    }
}
