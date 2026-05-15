//
//  CDFont+CDMarkdownKit.swift
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

internal extension CDFont {

    #if os(macOS)

        func bold() -> CDFont {
            NSFontManager.shared.convert(self,
                                         toHaveTrait: .boldFontMask)
        }

        func italic() -> CDFont {
            NSFontManager.shared.convert(self,
                                         toHaveTrait: .italicFontMask)
        }

        func withSize(_ fontSize: CGFloat) -> CDFont {
            NSFontManager.shared.convert(self,
                                         toSize: fontSize)
        }

    #else

        private func withTraits(_ traits: CDFontDescriptorSymbolicTraits...) -> CDFont {
            guard let descriptor = fontDescriptor.withSymbolicTraits(CDFontDescriptorSymbolicTraits(traits)) else {
                return self
            }
            return CDFont(descriptor: descriptor, size: pointSize)
        }

        func bold() -> CDFont {
            withTraits(.traitBold)
        }

        func italic() -> CDFont {
            withTraits(.traitItalic)
        }

    #endif

    var isBold: Bool {
        #if os(macOS)
            return NSFontManager.shared.traits(of: self).contains(.boldFontMask)
        #else
            return fontDescriptor.symbolicTraits.contains(.traitBold)
        #endif
    }

    var isItalic: Bool {
        #if os(macOS)
            return NSFontManager.shared.traits(of: self).contains(.italicFontMask)
        #else
            return fontDescriptor.symbolicTraits.contains(.traitItalic)
        #endif
    }
}
