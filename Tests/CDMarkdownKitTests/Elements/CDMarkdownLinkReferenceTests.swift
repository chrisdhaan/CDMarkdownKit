import Foundation
import Testing
@testable import CDMarkdownKit

@MainActor
struct CDMarkdownLinkReferenceTests {

    let parser = CDMarkdownParser()

    @Test func fullReferenceRendersLink() async {
        let input = "[the guide][guide]\n\n[guide]: https://example.com"
        let result = await parser.parse(input)
        var foundURL: URL?
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL?.absoluteString == "https://example.com")
        #expect(result.string.contains("the guide"))
        #expect(!result.string.contains("[guide]"))
    }

    @Test func collapsedReferenceUsesDisplayText() async {
        let input = "[example][]\n\n[example]: https://example.com"
        let result = await parser.parse(input)
        var foundURL: URL?
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL?.absoluteString == "https://example.com")
    }

    @Test func referenceIdIsCaseInsensitive() async {
        let input = "[link][GUIDE]\n\n[guide]: https://example.com"
        let result = await parser.parse(input)
        var foundURL: URL?
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL?.absoluteString == "https://example.com")
    }

    @Test func definitionLineIsStrippedFromOutput() async {
        let input = "[link][ref]\n\n[ref]: https://example.com"
        let result = await parser.parse(input)
        #expect(!result.string.contains("[ref]"))
        #expect(!result.string.contains("https://example.com"))
    }

    @Test func titleIsWrittenAsAttribute() async {
        let input = "[link][ref]\n\n[ref]: https://example.com \"My Title\""
        let result = await parser.parse(input)
        var foundTitle: String?
        result.enumerateAttribute(.cdMarkdownLinkTitle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let title = value as? String { foundTitle = title }
        }
        #expect(foundTitle == "My Title")
    }

    @Test func unknownReferencePassesThroughAsText() async {
        let input = "[link][unknown]"
        let result = await parser.parse(input)
        var foundURL: URL?
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL == nil)
        #expect(result.string.contains("[link][unknown]"))
    }

    @Test func multipleReferencesResolveIndependently() async {
        let input = "[A][a] and [B][b]\n\n[a]: https://a.com\n[b]: https://b.com"
        let result = await parser.parse(input)
        var urls: [String] = []
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { urls.append(url.absoluteString) }
        }
        #expect(urls.contains("https://a.com"))
        #expect(urls.contains("https://b.com"))
    }

    @Test func definitionInsideFencedBlockIsNotExtracted() async {
        let input = "```\n[hidden]: https://hidden.com\n```"
        let result = await parser.parse(input)
        #expect(result.string.contains("[hidden]: https://hidden.com"))
    }

    @Test func definitionOutsideFencedBlockIsExtractedWhenFencedBlockPresent() async {
        let input = "[link][ref]\n```\nsome code\n```\n[ref]: https://example.com"
        let result = await parser.parse(input)
        var foundURL: URL?
        result.enumerateAttribute(.link,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let url = value as? URL { foundURL = url }
        }
        #expect(foundURL?.absoluteString == "https://example.com")
    }
}
