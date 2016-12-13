//
//  UIColor+CDMarkdownKit.swift
//  Pods
//
//  Created by Chris De Haan on 12/12/16.
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

public extension UIColor {

    static func codeTextRed() -> UIColor {
        return UIColor(red: 189/255.0, green: 0/255.0, blue: 58/255.0, alpha: 1.0)
    }
    
    static func codeBackgroundRed() -> UIColor {
        return UIColor(red: 247/255.0, green: 238/255.0, blue: 241/255.0, alpha: 1.0)
    }
    
    static func syntaxTextGray() -> UIColor {
        return UIColor(red: 57/255.0, green: 57/255.0, blue: 57/255.0, alpha: 1.0)
    }
    
    static func syntaxBackgroundGray() -> UIColor {
        return UIColor(red: 235/255.0, green: 235/255.0, blue: 235/255.0, alpha: 1.0)
    }
    
    func isEqualTo(otherColor : UIColor) -> Bool {
        if self == otherColor {
            return true
        }
        
        let colorSpaceRGB = CGColorSpaceCreateDeviceRGB()
        let convertColorToRGBSpace: ((_ color : UIColor) -> UIColor?) = { (color) -> UIColor? in
            if color.cgColor.colorSpace?.model == CGColorSpaceModel.monochrome {
                let oldComponents = color.cgColor.components
                let components: [CGFloat] = [oldComponents![0], oldComponents![0], oldComponents![0], oldComponents![1]]
                let colorRef = CGColor(colorSpace: colorSpaceRGB, components: components)
                let colorOut = UIColor(cgColor: colorRef!)
                return colorOut
            }
            else {
                return color;
            }
        }
        
        let selfColor = convertColorToRGBSpace(self)
        let otherColor = convertColorToRGBSpace(otherColor)
        
        if let selfColor = selfColor,
            let otherColor = otherColor {
            return selfColor.isEqual(otherColor)
        } else {
            return false
        }
    }
}
