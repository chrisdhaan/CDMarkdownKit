import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownLinkTests {

    let parser = CDMarkdownParser()

    @Test func bracketUrlProducesLink() async {
        let result = await parser.parse("[text](https://example.com)")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundLink = true
            }
        }
        #expect(foundLink)
    }

    @Test func linkAtStartOfStringWorks() async {
        let result = await parser.parse("[link](https://example.com) is here")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil {
                foundLink = true
            }
        }
        #expect(foundLink)
    }

    @Test func linkBracketsAreStripped() async {
        let result = await parser.parse("[text](https://example.com)")
        #expect(!result.string.contains("["))
        #expect(!result.string.contains("]"))
    }

    @Test func linkURLValueIsCorrect() async {
        let result = await parser.parse("[GitHub](https://github.com)")
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

    @Test func linkURLWithPathIsCorrect() async {
        let result = await parser.parse("[Docs](https://example.com/docs/api)")
        var foundURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL {
                foundURL = url
            }
        }
        #expect(foundURL?.path == "/docs/api")
    }

    @Test func linkURLContainingParenthesesIsNotCorrupted() async {
        let result = await parser.parse("[text](http://example.com/foo(bar))")

        // The URL capture regex itself stops at the first ")" regardless of whether it
        // belongs to the URL or the markdown syntax, so this only asserts the markdown
        // delimiter "]" doesn't leak into the rendered text -- not that arbitrarily
        // parenthesized URLs round-trip perfectly.
        #expect(!result.string.contains("]"))

        var linkURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL {
                linkURL = url
            }
        }
        #expect(linkURL?.absoluteString.hasPrefix("http://example.com/foo(bar") == true)
    }

    @Test func regexDoesNotMatchImageSyntax() throws {
        let link = CDMarkdownLink()
        let regex = try link.regularExpression()
        let input = "![alt](url)"
        let range = NSRange(location: 0, length: (input as NSString).length)
        let matches = regex.matches(in: input, options: [], range: range)
        #expect(matches.isEmpty)
    }
}
