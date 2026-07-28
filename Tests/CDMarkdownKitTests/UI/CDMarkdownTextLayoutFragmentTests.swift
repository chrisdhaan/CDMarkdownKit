import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
    @available(iOS 16.0, tvOS 16.0, *)
    @MainActor
    struct CDMarkdownTextLayoutFragmentTests {

        /// Lays out `markdown` in a fresh TextKit 2 stack and returns, per top-level text
        /// layout fragment (roughly: per paragraph), its document-absolute start offset and
        /// its line fragments — exactly the inputs `roundedBackgroundFills` needs.
        ///
        /// A freshly-initialized `NSTextContentStorage()` never auto-creates a default
        /// `NSTextLayoutManager` — `.textLayoutManagers` stays empty until one is explicitly
        /// created and added via `addTextLayoutManager(_:)`. This mirrors the construction
        /// pattern in `CDMarkdownLabel.configureTK2()`.
        private func layOutFragments(markdown: String) -> (
            textStorage: NSTextStorage,
            fragments: [(rangeStart: Int, lineFragments: [NSTextLineFragment])]
        ) {
            let parser = CDMarkdownParser()
            let attributedString = parser.parse(markdown)

            let contentStorage = NSTextContentStorage()
            let textStorage = NSTextStorage(attributedString: attributedString)
            contentStorage.textStorage = textStorage

            let layoutManager = NSTextLayoutManager()
            contentStorage.addTextLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: CGSize(width: 300, height: 1000))
            textContainer.lineFragmentPadding = 0
            layoutManager.textContainer = textContainer
            layoutManager.ensureLayout(for: layoutManager.documentRange)

            var fragments: [(Int, [NSTextLineFragment])] = []
            layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
                let start = contentStorage.offset(from: contentStorage.documentRange.location, to: fragment.rangeInElement.location)
                fragments.append((start, fragment.textLineFragments))
                return true
            }

            return (textStorage, fragments)
        }

        @Test func roundedBackgroundFillIsNarrowerThanFullLineWhenCodeSharesLineWithPlainText() {
            let (textStorage, fragments) = layOutFragments(markdown: "before `code` after")
            guard let firstFragment = fragments.first, let firstLine = firstFragment.lineFragments.first else {
                Issue.record("expected at least one laid-out line")
                return
            }

            let fills = CDMarkdownTextLayoutFragment.roundedBackgroundFills(fragmentRangeStart: firstFragment.rangeStart,
                                                                            textLineFragments: firstFragment.lineFragments,
                                                                            textStorage: textStorage,
                                                                            origin: .zero)

            #expect(fills.count == 1)
            guard let fill = fills.first else { return }
            // Full-line-width regression: pre-fix, this rect was the entire line's typographic
            // bounds starting at x == 0. Post-fix, it must be narrower than the line and start
            // after "before ".
            #expect(fill.rect.width < firstLine.typographicBounds.width)
            #expect(fill.rect.minX > 0)
        }

        @Test func roundedBackgroundFillUsesCorrectOffsetAcrossParagraphs() {
            let (textStorage, fragments) = layOutFragments(markdown: "first `alpha` line\n\nsecond `beta` line")
            #expect(fragments.count >= 2)
            guard fragments.count >= 2 else { return }

            let secondParagraph = fragments[1]

            // Correct offset: must find exactly one fill (the "beta" code span).
            let correctFills = CDMarkdownTextLayoutFragment.roundedBackgroundFills(fragmentRangeStart: secondParagraph.rangeStart,
                                                                                   textLineFragments: secondParagraph.lineFragments,
                                                                                   textStorage: textStorage,
                                                                                   origin: .zero)
            #expect(correctFills.count == 1)

            // Cross-paragraph regression: the pre-fix code used the fragment-local range
            // directly (equivalent to always passing a start offset of 0). Reproducing that
            // here on the second paragraph's real line fragments must NOT reproduce the
            // correct single-fill result, proving the offset translation is load-bearing.
            let zeroOffsetFills = CDMarkdownTextLayoutFragment.roundedBackgroundFills(fragmentRangeStart: 0,
                                                                                      textLineFragments: secondParagraph.lineFragments,
                                                                                      textStorage: textStorage,
                                                                                      origin: .zero)
            #expect(zeroOffsetFills != correctFills)
        }

        @Test func roundedBackgroundFillsEmptyWhenNoRoundedAttributePresent() {
            let (textStorage, fragments) = layOutFragments(markdown: "just plain text, no code spans")
            guard let firstFragment = fragments.first else {
                Issue.record("expected at least one laid-out fragment")
                return
            }

            let fills = CDMarkdownTextLayoutFragment.roundedBackgroundFills(fragmentRangeStart: firstFragment.rangeStart,
                                                                            textLineFragments: firstFragment.lineFragments,
                                                                            textStorage: textStorage,
                                                                            origin: .zero)
            #expect(fills.isEmpty)
        }
    }
#endif
