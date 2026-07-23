//
//  CDColor+CDMarkdownKit.swift
//  CDMarkdownKit
//
//  Created by Christopher de Haann on 12/12/16.
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

#if os(macOS)
    public extension CDColor {
        /// The primary label color, adapts to light and dark mode.
        static var label: CDColor { NSColor.labelColor }
    }
#elseif os(watchOS)
    public extension CDColor {
        /// The primary label color. watchOS is dark-first; white is the standard text color.
        static var label: CDColor { .white }
    }
#endif

public extension CDColor {

    static func codeTextRed() -> CDColor {
        CDColor(red: 189 / 255.0,
                green: 0 / 255.0,
                blue: 58 / 255.0,
                alpha: 1.0)
    }

    static func codeBackgroundRed() -> CDColor {
        CDColor(red: 247 / 255.0,
                green: 238 / 255.0,
                blue: 241 / 255.0,
                alpha: 1.0)
    }

    static func syntaxTextGray() -> CDColor {
        CDColor(red: 57 / 255.0,
                green: 57 / 255.0,
                blue: 57 / 255.0,
                alpha: 1.0)
    }

    static func syntaxBackgroundGray() -> CDColor {
        CDColor(red: 235 / 255.0,
                green: 235 / 255.0,
                blue: 235 / 255.0,
                alpha: 1.0)
    }

    func isEqualTo(otherColor: CDColor) -> Bool {
        if self == otherColor {
            return true
        }

        let colorSpaceRGB = CGColorSpaceCreateDeviceRGB()
        let convertColorToRGBSpace: ((_ color: CDColor) -> CDColor?) = { color -> CDColor? in
            if color.cgColor.colorSpace?.model == CGColorSpaceModel.monochrome {
                guard let oldComponents = color.cgColor.components,
                      oldComponents.count >= 2 else { return nil }
                let components: [CGFloat] = [oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]]
                guard let colorRef = CGColor(colorSpace: colorSpaceRGB,
                                             components: components) else { return nil }
                return CDColor(cgColor: colorRef)
            } else {
                return color
            }
        }

        let selfColor = convertColorToRGBSpace(self)
        let otherColor = convertColorToRGBSpace(otherColor)

        if let selfColor,
           let otherColor {
            return selfColor.isEqual(otherColor)
        } else {
            return false
        }
    }
}
