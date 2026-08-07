#if os(macOS)

    import Cocoa
    import Testing
    @testable import CDMarkdownKit

    @MainActor
    struct CDMarkdownNSLayoutManagerTests {

        @Test func roundAllCornersDefaultsFalse() {
            let layoutManager = CDMarkdownNSLayoutManager()
            #expect(layoutManager.roundAllCorners == false)
        }

        @Test func fillBackgroundRectArraySingleRectDoesNotCrash() {
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage(string: "code")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 4))
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 40))
            image.lockFocus()
            let rects = [NSRect(x: 0, y: 0, width: 80, height: 20)]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 0, length: 4),
                                                      color: .red)
            }
            image.unlockFocus()
            #expect(layoutManager.textStorage === textStorage)
        }

        @Test func fillBackgroundRectArrayTwoDisjointRectsDoesNotCrash() {
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage(string: "wrapped code")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 12))
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 60))
            image.lockFocus()
            // Two rects with a gap (rects[1].maxX < rects[0].minX) -- macOS draws every rect through
            // the same uniform loop regardless of count; this exercises it with two disjoint rects.
            let rects = [
                NSRect(x: 60, y: 0, width: 40, height: 20),
                NSRect(x: 0, y: 20, width: 20, height: 20)
            ]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 0, length: 12),
                                                      color: .red)
            }
            image.unlockFocus()
        }

        @Test func fillBackgroundRectArrayThreeWrappedRectsDoesNotCrash() {
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage(string: "a longer wrapped code span")
            textStorage.addAttribute(.cdMarkdownRoundedBackground, value: true, range: NSRange(location: 0, length: 26))
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 60))
            image.lockFocus()
            // Three rects spanning wrapped lines -- macOS draws every rect through
            // the same uniform loop regardless of count; this exercises it with three rects.
            let rects = [
                NSRect(x: 40, y: 0, width: 40, height: 20),
                NSRect(x: 0, y: 20, width: 100, height: 20),
                NSRect(x: 0, y: 40, width: 30, height: 20)
            ]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 0, length: 26),
                                                      color: .red)
            }
            image.unlockFocus()
        }

        @Test func fillBackgroundRectArrayHonorsRoundAllCornersWhenAttributeAbsent() {
            let layoutManager = CDMarkdownNSLayoutManager()
            layoutManager.roundAllCorners = true
            let textStorage = NSTextStorage(string: "plain text, no code attribute")
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 40))
            image.lockFocus()
            let rects = [NSRect(x: 0, y: 0, width: 80, height: 20)]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 0, length: 5),
                                                      color: .blue)
            }
            image.unlockFocus()
        }

        @Test func fillBackgroundRectArrayFallsBackToSuperWhenNeitherRoundAllCornersNorAttributeSet() {
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage(string: "plain text")
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 40))
            image.lockFocus()
            let rects = [NSRect(x: 0, y: 0, width: 80, height: 20)]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 0, length: 5),
                                                      color: .green)
            }
            image.unlockFocus()
            #expect(layoutManager.roundAllCorners == false)
        }

        @Test func hasRoundedAttributeReturnsFalseWhenRangeAtTextStorageLength() {
            let layoutManager = CDMarkdownNSLayoutManager()
            let textStorage = NSTextStorage(string: "abc")
            textStorage.addLayoutManager(layoutManager)

            let image = NSImage(size: NSSize(width: 100, height: 40))
            image.lockFocus()
            // charRange.location (3) == textStorage.length (3) -- the boundary
            // hasRoundedAttribute(at:) guards against with `charRange.location < textStorage.length`.
            let rects = [NSRect(x: 0, y: 0, width: 80, height: 20)]
            rects.withUnsafeBufferPointer { buffer in
                layoutManager.fillBackgroundRectArray(buffer.baseAddress!,
                                                      count: buffer.count,
                                                      forCharacterRange: NSRange(location: 3, length: 0),
                                                      color: .red)
            }
            image.unlockFocus()
        }
    }

#endif
