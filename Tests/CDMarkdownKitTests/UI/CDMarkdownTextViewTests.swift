import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @MainActor
    struct CDMarkdownTextViewTests {

        @Test func secondAttributedTextAssignmentKeepsLayoutManagerAttachedToRealTextStorage() async {
            // Build a self-consistent TK1 stack (textStorage -> layoutManager -> textContainer)
            // up front, mirroring the end state that `configureTK1()` produces on a real device
            // running iOS/tvOS 15 -- `UITextView(frame:textContainer:)` requires the container it
            // is given to already belong to a layout manager, so the layout manager and text
            // storage must be wired together before construction.
            let layoutManager = CDMarkdownLayoutManager()
            let textContainer = NSTextContainer(size: CGSize(width: 200, height: 200))
            layoutManager.addTextContainer(textContainer)
            let textStorage = NSTextStorage()
            textStorage.addLayoutManager(layoutManager)

            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                                              textContainer: textContainer,
                                              layoutManager: layoutManager)
            // Force the TK1 configuration path directly, since it's only auto-selected below iOS 16.
            let parser = CDMarkdownParser()
            textView.attributedText = await parser.parse("first")
            textView.attributedText = await parser.parse("second")

            #expect(textView.textStorage.layoutManagers.contains(where: { $0 === textView.customLayoutManager }))
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func configureTK2SetsTK2Delegate() {
            // A nil textContainer lets UIKit set up its own native TextKit 2 stack. A bare,
            // unattached NSTextContainer() would crash: UIKit's TextKit-1-compatibility
            // layout controller requires the container to already have a layout manager
            // attached before it's handed to UITextView's initializer.
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK2()
            #expect(textView.tk2Delegate is CDMarkdownTextLayoutDelegate)
        }

        @Test func configureTK1AttachesCustomLayoutManagerToTextStorage() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK1()
            #expect(textView.customLayoutManager != nil)
            #expect(textView.textStorage.layoutManagers.contains(where: { $0 === textView.customLayoutManager }))
        }

        @Test func makeTextViewFactoryConfiguresTextView() {
            let textView = CDMarkdownTextView.makeTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            #expect(textView.isScrollEnabled == true)
            #expect(textView.isSelectable == false)
        }

        @Test func initWithFrameAndNilTextContainerAutoConfigures() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            if #available(iOS 16.0, tvOS 16.0, *) {
                #expect(textView.tk2Delegate is CDMarkdownTextLayoutDelegate)
            } else {
                #expect(textView.customLayoutManager != nil)
            }
            #expect(textView.isScrollEnabled == true)
            #expect(textView.isSelectable == false)
        }

        @Test func settingAttributedTextOnTK1ConfiguredViewPopulatesCustomTextStorage() async {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK1()
            let parser = CDMarkdownParser()
            textView.attributedText = await parser.parse("hello")

            #expect(textView.customTextStorage === textView.textStorage)
        }

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundAllCornersPropagatesToTK2Delegate() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.configureTK2()
            textView.roundAllCorners = true

            guard let delegate = textView.tk2Delegate as? CDMarkdownTextLayoutDelegate else {
                Issue.record("expected a CDMarkdownTextLayoutDelegate")
                return
            }
            #expect(delegate.roundAllCorners == true)
        }

        @Test func roundAllCornersPropagatesToTK1LayoutManagerWhenTK2NotConfigured() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            // roundAllCorners's didSet routes on whether tk2Delegate currently holds a
            // CDMarkdownTextLayoutDelegate; clear it so the TK1 branch is exercised even
            // though init() now runs configureTK2() on a modern simulator.
            textView.tk2Delegate = nil
            textView.configureTK1()
            textView.roundAllCorners = true

            #expect(textView.customLayoutManager.roundAllCorners == true)
        }

        @Test func parsedSwiftBlockRetainsDistinctTokenColorsInTextStorage() async {
            // End-to-end: syntax token colours survive the full
            // parse -> NSAttributedString -> CDMarkdownTextView pipeline and reach the
            // view's text storage as distinct `.foregroundColor` runs.
            let parser = CDMarkdownParser()
            parser.syntax.syntaxColors = [.keyword: .red, .string: .green]
            let attributed = await parser.parse("```swift\nlet s = \"hi\"\n```")

            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.attributedText = attributed

            let storage = textView.textStorage
            var sawRed = false
            var sawGreen = false
            var distinct: [CDColor] = []
            storage.enumerateAttribute(.foregroundColor,
                                       in: NSRange(location: 0, length: storage.length)) { value, _, _ in
                guard let color = value as? CDColor else { return }
                if color == CDColor.red {
                    sawRed = true
                }
                if color == CDColor.green {
                    sawGreen = true
                }
                if !distinct.contains(color) {
                    distinct.append(color)
                }
            }
            #expect(sawRed)
            #expect(sawGreen)
            #expect(distinct.count >= 2)
        }

        // MARK: - intrinsicContentSize

        @Test func intrinsicContentSizeReportsMeasuredHeightWhenScrollingDisabled() async {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.isScrollEnabled = false
            let parser = CDMarkdownParser()
            textView.attributedText = await parser.parse(
                "# Heading\n\nA paragraph long enough to wrap onto several lines when it is "
                    + "constrained to three hundred points of width."
            )

            let size = textView.intrinsicContentSize
            let expected = textView.sizeThatFits(CGSize(width: textView.bounds.width,
                                                        height: .greatestFiniteMagnitude))
            #expect(size.width == UIView.noIntrinsicMetric)
            #expect(size.height == expected.height)
            #expect(size.height > 0)
        }

        @Test func intrinsicContentSizeStaysNoIntrinsicMetricWhenScrollingEnabled() async {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            // Default: isScrollEnabled == true -- existing callers see no behavior change.
            textView.attributedText = await CDMarkdownParser().parse("plenty of words here to wrap")

            #expect(textView.intrinsicContentSize.height == UIView.noIntrinsicMetric)
        }

        @Test func intrinsicContentSizeIsSafeForEmptyTextWhenScrollingDisabled() {
            let textView = CDMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                              textContainer: nil)
            textView.isScrollEnabled = false
            let size = textView.intrinsicContentSize
            #expect(size.width == UIView.noIntrinsicMetric)
            #expect(size.height.isFinite)
        }

        @Test func settingAttributedTextInvalidatesIntrinsicContentSize() async {
            let textView = SpyTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                       textContainer: nil)
            textView.invalidateCount = 0

            textView.attributedText = await CDMarkdownParser().parse("hello")

            #expect(textView.invalidateCount == 1)
        }

        @Test func layoutSubviewsInvalidatesIntrinsicContentSizeOnlyWhenWidthChanges() {
            let textView = SpyTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200),
                                       textContainer: nil)
            textView.frame = CGRect(x: 0, y: 0, width: 250, height: 200)
            textView.invalidateCount = 0

            textView.layoutSubviews()
            let afterWidthChange = textView.invalidateCount

            textView.layoutSubviews()
            let afterSameWidth = textView.invalidateCount

            #expect(afterWidthChange == 1)
            #expect(afterSameWidth == afterWidthChange)
        }
    }

    /// Counts `invalidateIntrinsicContentSize()` calls so tests can assert the view
    /// invalidates its layout at the right moments.
    @MainActor
    private final class SpyTextView: CDMarkdownTextView {

        var invalidateCount = 0

        override func invalidateIntrinsicContentSize() {
            invalidateCount += 1
            super.invalidateIntrinsicContentSize()
        }
    }
#endif
