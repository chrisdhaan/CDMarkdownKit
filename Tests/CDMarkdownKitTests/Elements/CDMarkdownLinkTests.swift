import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownLinkTests {

    let parser = CDMarkdownParser()

    @Test func bracketUrlProducesLink() {
        let result = parser.parse("[text](https://example.com)")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundLink = true
            }
        }
        #expect(foundLink)
    }

    @Test func linkAtStartOfStringWorks() {
        let result = parser.parse("[link](https://example.com) is here")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundLink = true
            }
        }
        #expect(foundLink)
    }

    @Test func linkBracketsAreStripped() {
        let result = parser.parse("[text](https://example.com)")
        #expect(!result.string.contains("["))
        #expect(!result.string.contains("]"))
    }

    @Test func linkURLValueIsCorrect() {
        let result = parser.parse("[GitHub](https://github.com)")
        var foundURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL {
                foundURL = url
            }
        }
        #expect(foundURL != nil)
        #expect(foundURL?.host == "github.com")
        #expect(foundURL?.scheme == "https")
    }

    @Test func linkURLWithPathIsCorrect() {
        let result = parser.parse("[Docs](https://example.com/docs/api)")
        var foundURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL {
                foundURL = url
            }
        }
        #expect(foundURL?.path == "/docs/api")
    }

    @Test func linkURLContainingParenthesesIsNotCorrupted() {
        let result = parser.parse("[text](http://example.com/foo(bar))")

        // Before the fix, the backward "(" search landed on the paren inside the URL
        // instead of the real delimiter, corrupting the visible text down to something
        // like "text](http://example.com/fo)" -- the markdown delimiter "]" leaking into
        // the rendered text is the signature of the bug. (Note: the regex's URL capture
        // group itself always stops at the *first* ")" it encounters, whether that paren
        // belongs to the URL or the markdown syntax -- that's a separate, pre-existing
        // regex limitation this fix does not attempt to change. This test only asserts
        // the delimiter-detection bug is fixed, not that arbitrarily-parenthesized URLs
        // round-trip perfectly.)
        #expect(!result.string.contains("]"))

        var linkURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL {
                linkURL = url
            }
        }
        #expect(linkURL?.absoluteString.hasPrefix("http://example.com/foo(bar") == true)
    }
}
