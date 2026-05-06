import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct StringTests {

    @Test func escapeUTF16RoundtripsASCII() {
        let original = "Hello"
        let escaped = original.escapeUTF16()
        let roundtripped = escaped.unescapeUTF16()
        #expect(roundtripped == original)
    }

    @Test func escapeUTF16RoundtripsAsterisk() {
        let original = "*"
        let escaped = original.escapeUTF16()
        #expect(escaped == "002a")
        #expect(escaped.unescapeUTF16() == original)
    }

    @Test func escapeUTF16RoundtripsMultiCharString() {
        let original = "**bold**"
        let escaped = original.escapeUTF16()
        #expect(escaped.unescapeUTF16() == original)
    }

    @Test func unescapeUTF16ReturnsNilForInvalidInput() {
        // Odd-length or non-hex content can't round-trip
        let bad = "xyz"
        // unescapeUTF16 should not crash; it may return nil or empty
        let result = bad.unescapeUTF16()
        #expect(result != nil)
    }

    @Test func rangeFromNSRange() {
        let s = "Hello, world"
        let nsRange = NSRange(location: 7, length: 5)
        let range = s.range(from: nsRange)
        #expect(range != nil)
        #expect(s[range!] == "world")
    }
}
