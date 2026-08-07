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

        @Test func setAttributedStringUpdatesCustomTextStorage() {
            let textView = CDMarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            let attributed = parser.parse("Hello **world**")

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
    }

#endif
