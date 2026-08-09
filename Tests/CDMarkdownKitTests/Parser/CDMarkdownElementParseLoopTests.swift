import Foundation
import Testing
@testable import CDMarkdownKit

/// A CDMarkdownElement whose regex produces a zero-length match fixed at the position
/// right after the leading "a", and whose match() never changes the string's length.
/// This is the exact shape of custom element that can hang the default parse() loop
/// if it doesn't force position to advance past zero-length matches: the lookbehind
/// keeps matching the same position forever because nothing before it ever changes.
///
/// matchCount is capped as a runaway safety valve: if parse() isn't advancing past
/// the zero-length match, this element deletes the leading "a" once the cap is hit,
/// which removes the only anchor the lookbehind can match against. Deleting exactly
/// one character strictly before the match's start (position 1) keeps the parse()
/// loop's location arithmetic non-negative even under the unfixed, buggy formula,
/// so a regression fails a bounded assertion instead of hanging or crashing.
private final class ZeroLengthLookbehindElement: CDMarkdownElement {
    let regex = "(?<=a)"
    private(set) var matchCount = 0
    private let matchCap = 50

    func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex)
    }

    func match(_ result: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        matchCount += 1
        if matchCount >= matchCap {
            attributedString.deleteCharacters(in: NSRange(location: 0, length: 1))
        }
    }
}

extension ZeroLengthLookbehindElement: @unchecked Sendable {}

/// A CDMarkdownElement whose regex produces a zero-length match only at the very end
/// of the string (no character follows). Forcing the parse() loop's location forward
/// by at least one past a zero-length match's start must not push location past the
/// string's length, or the next search range becomes invalid (negative length).
private final class ZeroLengthEndOfStringElement: CDMarkdownElement {
    let regex = "(?!.)"
    private(set) var matchCount = 0

    func regularExpression() throws -> NSRegularExpression {
        try NSRegularExpression(pattern: regex)
    }

    func match(_ result: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        matchCount += 1
    }
}

extension ZeroLengthEndOfStringElement: @unchecked Sendable {}

@MainActor
struct CDMarkdownElementParseLoopTests {

    @Test func parseLoopAdvancesPastZeroLengthMatches() {
        // Given: "(?<=a)" matches only once, right after the leading "a".
        let element = ZeroLengthLookbehindElement()
        let attributedString = NSMutableAttributedString(string: "abb")

        // When
        element.parse(attributedString)

        // Then: a correctly-advancing loop matches exactly once; a loop stuck
        // re-matching the same position forever hits the safety cap instead.
        #expect(element.matchCount == 1)
    }

    @Test func parseLoopHandlesZeroLengthMatchAtEndOfString() {
        // Given: "(?!.)" matches only once, at the very end of "xyz".
        let element = ZeroLengthEndOfStringElement()
        let attributedString = NSMutableAttributedString(string: "xyz")

        // When: this must not crash by searching an invalid negative-length range
        // after forcing location one past the match's start.
        element.parse(attributedString)

        // Then
        #expect(element.matchCount == 1)
    }
}
