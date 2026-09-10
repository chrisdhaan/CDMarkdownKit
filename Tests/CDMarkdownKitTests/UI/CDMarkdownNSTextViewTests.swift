#if os(macOS)

    import Cocoa
    import Testing
    @testable import CDMarkdownKit

    @MainActor
    struct CDMarkdownNSTextViewTests {

        let parser = CDMarkdownParser()

        @Test func configureWiresCustomLayoutManagerAsTextViewsActiveLayoutManager() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            #expect(textView.customLayoutManager != nil)
            #expect(textView.layoutManager === textView.customLayoutManager)
        }

        @Test func configureWiresCustomTextStorageAsTextViewsActiveTextStorage() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            #expect(textView.customTextStorage != nil)
            #expect(textView.textStorage === textView.customTextStorage)
        }

        @Test func configureMakesTextViewReadOnlyButSelectable() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            #expect(textView.isEditable == false)
            #expect(textView.isSelectable == true)
        }

        @Test func configureGivesTextContainerAFiniteWidthThatTracksTheView() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            #expect(textView.textContainer?.widthTracksTextView == true)
            #expect(textView.textContainer?.containerSize.width == 300)
        }

        @Test func setAttributedStringUpdatesCustomTextStorage() async {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            let attributed = await parser.parse("Hello **world**")

            textView.setAttributedString(attributed)

            #expect(textView.customTextStorage.string == attributed.string)
            #expect(textView.textStorage?.string == attributed.string)
        }

        @Test func roundAllCornersPropagatesToCustomLayoutManager() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            textView.roundAllCorners = true
            #expect(textView.customLayoutManager.roundAllCorners == true)
        }

        @Test func roundAllCornersDefaultsFalse() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            #expect(textView.roundAllCorners == false)
            #expect(textView.customLayoutManager.roundAllCorners == false)
        }

        @Test func initWithCoderWiresCustomLayoutManagerAndTextStorageAsTextViewsActiveTextSystem() throws {
            let original = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: false)

            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            let decoded = unarchiver.decodeObject(
                of: CDMarkdownNSTextView.self,
                forKey: NSKeyedArchiveRootObjectKey
            )
            unarchiver.finishDecoding()
            let textView = try #require(decoded)

            #expect(textView.customLayoutManager != nil)
            #expect(textView.customTextStorage != nil)
            #expect(textView.layoutManager === textView.customLayoutManager)
            #expect(textView.textStorage === textView.customTextStorage)
        }

        // MARK: - intrinsicContentSize

        @Test func intrinsicContentSizeReportsFittingHeightAndNoIntrinsicWidth() async {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            await textView.setAttributedString(
                parser.parse(
                    "# Heading\n\nA paragraph long enough to wrap onto several lines "
                        + "when it is constrained to three hundred points of width."
                )
            )

            let size = textView.intrinsicContentSize
            #expect(size.width == NSView.noIntrinsicMetric)
            #expect(size.height == textView.fittingHeight(forWidth: textView.bounds.width))
            #expect(size.height > 0)
        }

        @Test func intrinsicContentSizeHeightGrowsWithLongerText() async {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))

            await textView.setAttributedString(parser.parse("one line"))
            let shortHeight = textView.intrinsicContentSize.height

            await textView.setAttributedString(
                parser.parse(Array(repeating: "line", count: 40).joined(separator: "\n\n"))
            )
            let tallHeight = textView.intrinsicContentSize.height

            #expect(tallHeight > shortHeight)
        }

        @Test func intrinsicContentSizeIsSafeForEmptyText() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            let size = textView.intrinsicContentSize
            #expect(size.height >= 0)
            #expect(size.height.isFinite)
        }

        @Test func setAttributedStringInvalidatesIntrinsicContentSize() async {
            let textView = SpyNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            textView.invalidateCount = 0

            await textView.setAttributedString(parser.parse("Hello **world**"))

            #expect(textView.invalidateCount == 1)
        }

        @Test func layoutInvalidatesIntrinsicContentSizeOnlyWhenWidthChanges() async {
            let textView = SpyNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            await textView.setAttributedString(parser.parse("Hello"))
            textView.invalidateCount = 0

            textView.setFrameSize(NSSize(width: 250, height: 100))
            textView.layout()
            #expect(textView.invalidateCount == 1)

            textView.layout()
            #expect(textView.invalidateCount == 1)
        }
    }

    /// Counts `invalidateIntrinsicContentSize()` calls so tests can assert the view
    /// invalidates its layout at the right moments.
    @MainActor
    private final class SpyNSTextView: CDMarkdownNSTextView {

        var invalidateCount = 0

        override func invalidateIntrinsicContentSize() {
            invalidateCount += 1
            super.invalidateIntrinsicContentSize()
        }
    }

#endif
