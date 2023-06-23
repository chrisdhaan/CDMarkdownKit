//
//  NSLayoutManager+CDMarkdownKit.swift
//  CDMarkdownKit
//
//  Created by 박형환 on 2023/06/24.
//  Copyright © 2023 Christopher de Haan. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif



extension NSLayoutManager{
    /// Determine the character ranges for an attachment
    private func rangesForAttachment(attachment: NSTextAttachment) -> [NSRange]?{
        guard let attributedString = self.textStorage else
        {
            return nil
        }
        
        // find character range for this attachment
        let range = NSRange(location: 0, length: attributedString.length)
        
        var refreshRanges = [NSRange]()
        
        attributedString.enumerateAttribute(NSAttributedString.Key.attachment,
                                            in: range, options: []) {
            (value, effectiveRange, nil) in
            
            guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment else
            {
                return
            }
            
            // add this range to the refresh ranges
            refreshRanges.append(effectiveRange)
        }
        
        if refreshRanges.count == 0
        {
            return nil
        }
        
        return refreshRanges
    }
    
    /// Trigger a re-display for an attachment
    public func setNeedsDisplay(forAttachment attachment: NSTextAttachment){
        guard let ranges = rangesForAttachment(attachment: attachment) else
        {
            return
        }
        
        // invalidate the display for the corresponding ranges
        ranges.reversed().forEach { (range) in
            self.invalidateDisplay(forGlyphRange: range)
        }
    }
    /// Trigger a relayout for an attachment
    public func setNeedsLayout(forAttachment attachment: NSTextAttachment){
        guard let ranges = rangesForAttachment(attachment: attachment) else
        {
            return
        }
        
        
        // invalidate the display for the corresponding ranges
        ranges.reversed().forEach { (range) in
            self.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
            
            // also need to trigger re-display or already visible images might not get updated
            self.invalidateDisplay(forGlyphRange: range)
        }
    }
}
