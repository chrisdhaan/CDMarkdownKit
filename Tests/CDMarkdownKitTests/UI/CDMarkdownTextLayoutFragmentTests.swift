import Foundation
import Testing
#if os(iOS) || os(tvOS) || os(visionOS)
    import UIKit
#endif
@testable import CDMarkdownKit

#if os(iOS) || os(tvOS) || os(visionOS)
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
        @available(iOS 16.0, tvOS 16.0, *)
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

        @available(iOS 16.0, tvOS 16.0, *)
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

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundedBackgroundFillUsesCorrectOffsetAcrossParagraphs() {
            // squashNewlines (default true) collapses "\n\n" to "\n" before parsing, so this still yields
            // exactly 2 paragraphs/fragments — not 3, and not 1.
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

            guard let correctFill = correctFills.first, let secondLine = secondParagraph.lineFragments.first else {
                Issue.record("expected a fill and a line fragment")
                return
            }
            // Positive geometry regression: a `subrangeInLine` translation regression (e.g.
            // `subrange.location - absoluteLocation` accidentally becoming `subrange.location`)
            // would still produce a single fill, but with garbage/clamped geometry. Asserting on
            // the fill's actual rect — not just its count — catches that case.
            #expect(correctFill.rect.width < secondLine.typographicBounds.width)
            #expect(correctFill.rect.minX > 0)

            // zeroOffsetFills still differs from correctFills here because "alpha" and "beta" sit at
            // different local character indices within their lines — but the geometry assertions above
            // are the real regression guard; this comparison is a secondary signal, not the primary one.
            //
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

        @available(iOS 16.0, tvOS 16.0, *)
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

        @available(iOS 16.0, tvOS 16.0, *)
        @Test func roundedBackgroundFillsSkipsOutOfBoundsLines() {
            let (textStorage, fragments) = layOutFragments(markdown: "before `code` after")
            guard let firstFragment = fragments.first else {
                Issue.record("expected at least one laid-out fragment")
                return
            }

            let fills = CDMarkdownTextLayoutFragment.roundedBackgroundFills(fragmentRangeStart: textStorage.length + 1000,
                                                                            textLineFragments: firstFragment.lineFragments,
                                                                            textStorage: textStorage,
                                                                            origin: .zero)
            #expect(fills.isEmpty)
        }
    }
#endif
