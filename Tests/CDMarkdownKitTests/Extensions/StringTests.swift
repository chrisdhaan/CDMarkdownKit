import Foundation
import Testing
@testable import CDMarkdownKit

struct StringTests {

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

    @Test func unescapeUTF16ReturnsEmptyStringForInvalidInput() {
        // Content shorter than one 4-hex-digit group can't be decoded into any UTF-16 code
        // units, so this yields an empty string rather than nil -- unescapeUTF16()'s only
        // construction path, String(utf16CodeUnits:count:), never actually fails, so the
        // function's `String?` return type is vestigial.
        let bad = "xyz"
        let result = bad.unescapeUTF16()
        #expect(result == "")
    }

    @Test func rangeFromNSRange() throws {
        let s = "Hello, world"
        let nsRange = NSRange(location: 7, length: 5)
        let range = s.range(from: nsRange)
        #expect(range != nil)
        #expect(try s[#require(range)] == "world")
    }
}
