#if os(macOS)

    import Cocoa
    import Testing
    @testable import CDMarkdownKit

    @MainActor
    struct CDMarkdownNSLabelTests {

        let parser = CDMarkdownParser()

        @Test func labelAcceptsAttributedText() async {
            let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            label.attributedText = await parser.parse("Hello **world**")
            #expect(label.attributedText.length > 0)
        }

        @Test func labelIntrinsicHeightIsPositive() async {
            let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            label.attributedText = await parser.parse("Hello **world**")
            #expect(label.intrinsicContentSize.height > 0)
        }

        @Test func roundAllCornersFlag() {
            let label = CDMarkdownNSLabel(frame: .zero)
            label.roundAllCorners = true
            #expect(label.roundAllCorners == true)
        }

        @Test func labelDrawWithCodeSpanDoesNotCrash() async {
            let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 200, height: 60))
            label.attributedText = await parser.parse("`code span`")
            label.layout()

            guard let rep = label.bitmapImageRepForCachingDisplay(in: label.bounds) else {
                Issue.record("expected a bitmap image rep for caching display")
                return
            }
            label.cacheDisplay(in: label.bounds, to: rep)

            #expect(rep.tiffRepresentation != nil)
        }

        @Test func labelRoundAllCornersChangesRenderedPixelsForBackgroundColoredText() {
            func renderedTIFF(roundAllCorners: Bool) -> Data? {
                let attributedString = NSMutableAttributedString(string: "background text")
                attributedString.addAttribute(.backgroundColor,
                                              value: CDColor.red,
                                              range: NSRange(location: 0, length: attributedString.length))

                let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 200, height: 60))
                label.roundAllCorners = roundAllCorners
                label.attributedText = attributedString
                label.layout()
                guard let rep = label.bitmapImageRepForCachingDisplay(in: label.bounds) else { return nil }
                label.cacheDisplay(in: label.bounds, to: rep)
                return rep.tiffRepresentation
            }

            let square = renderedTIFF(roundAllCorners: false)
            let rounded = renderedTIFF(roundAllCorners: true)

            #expect(square != nil)
            #expect(rounded != nil)
            #expect(square != rounded)
        }
    }

#endif
