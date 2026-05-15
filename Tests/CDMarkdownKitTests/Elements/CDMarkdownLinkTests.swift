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
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    @Test func linkAtStartOfStringWorks() {
        let result = parser.parse("[link](https://example.com) is here")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(foundLink)
    }

    @Test func imageNotTreatedAsLink() {
        let result = parser.parse("![alt](https://example.com/image.png)")
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if v != nil { foundLink = true }
        }
        #expect(!foundLink)
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
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL != nil)
        #expect(foundURL?.host == "github.com")
        #expect(foundURL?.scheme == "https")
    }

    @Test func linkURLWithPathIsCorrect() {
        let result = parser.parse("[Docs](https://example.com/docs/api)")
        var foundURL: URL?
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL?.path == "/docs/api")
    }
}
