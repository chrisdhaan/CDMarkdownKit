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
    }

#endif
