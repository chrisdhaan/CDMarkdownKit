# CDMarkdownKit — Improvements Plan

> Implementation plan for improvements to CDMarkdownKit following the v3.1.0 release. Each section is self-contained and can be implemented independently unless a prerequisite is noted. Sections are ordered to minimize cross-section dependencies.
>
> Sections are ordered for sequential implementation:
> 1. Swift 6 Language Mode (foundational, no dependencies)
> 2. Missing GFM Features (parser-only, no dependencies)
> 3. API Ergonomics (shapes public API before SwiftUI exposure)
> 4. Accessibility (attributed string level, no rendering stack dependency)
> 5. macOS UI Components (prerequisite for full SwiftUI macOS support)
> 6. SwiftUI Wrappers (depends on section 5 for macOS)

---

## 1. Swift 6 Language Mode

CDMarkdownKit currently compiles in Swift 5 language mode (`swiftLanguageModes: [.v5]`) on a Swift 6 toolchain. Section 7 of IMPLEMENTATION.md performed the concurrency audit and added `@MainActor` / `Sendable` annotations, but never flipped the language mode flag. Completing this transition makes CDMarkdownKit a fully modern Swift 6 package and prevents a growing backlog of suppressed warnings as the Swift compiler evolves.

**Prerequisite**: None.

---

### Steps

**1.1 — Flip `swiftLanguageModes` in `Package.swift`** ✅

Open `Package.swift`. Change:

```swift
swiftLanguageModes: [.v5]
```

to:

```swift
swiftLanguageModes: [.v6]
```

Run `swift build`. Collect every error and warning produced. Do not fix anything yet — read all diagnostics first to understand the full scope.

---

**1.2 — Fix `Sendable` conformance on element protocol types** ✅

Swift 6 enforces that types crossing actor boundaries conform to `Sendable`. The element protocols and their concrete types were annotated in IMPLEMENTATION.md section 7.3 with `@unchecked Sendable`. Under Swift 6 mode, verify these annotations are still sufficient. For any class that the compiler still flags:

- If the class has only `CDFont?`, `CDColor?`, `NSParagraphStyle?`, and `String` stored properties, those are all `Sendable` on Apple platforms — change `@unchecked Sendable` to plain `: Sendable` where synthesis works.
- For `open class` types (which cannot use synthesis because subclasses could add non-Sendable properties), keep `@unchecked Sendable` and add a comment explaining why.

Files to check (all conformers of `CDMarkdownElement`):
- `Source/CDMarkdownBold.swift`
- `Source/CDMarkdownItalic.swift`
- `Source/CDMarkdownHeader.swift`
- `Source/CDMarkdownList.swift`
- `Source/CDMarkdownOrderedList.swift`
- `Source/CDMarkdownQuote.swift`
- `Source/CDMarkdownLink.swift`
- `Source/CDMarkdownAutomaticLink.swift`
- `Source/CDMarkdownImage.swift`
- `Source/CDMarkdownCode.swift`
- `Source/CDMarkdownSyntax.swift`
- `Source/CDMarkdownStrikethrough.swift`
- `Source/CDMarkdownTable.swift`
- `Source/CDMarkdownCodeEscaping.swift`
- `Source/CDMarkdownEscaping.swift`
- `Source/CDMarkdownUnescaping.swift`

---

**1.3 — Fix `any` keyword requirements from `ExistentialAny`** ✅

The `ExistentialAny` upcoming feature flag (added in IMPLEMENTATION.md step 7.2) requires the `any` keyword on all existential type uses. Under Swift 6 mode this becomes an error, not just a warning.

Search for all uses of bare protocol types as existentials and add `any`:

```bash
grep -rn "CDMarkdownElement\b" Source/ | grep -v "any CDMarkdownElement"
grep -rn "CDMarkdownStyle\b" Source/ | grep -v "any CDMarkdownStyle"
grep -rn "CDMarkdownCommonElement\b" Source/ | grep -v "any CDMarkdownCommonElement"
grep -rn "CDMarkdownLevelElement\b" Source/ | grep -v "any CDMarkdownLevelElement"
grep -rn "CDMarkdownLinkElement\b" Source/ | grep -v "any CDMarkdownLinkElement"
```

For each hit that is a type annotation (not a conformance declaration or type constraint), prepend `any`. Example:

```swift
// BEFORE:
var customElements: [CDMarkdownElement] = []
var defaultElements: [CDMarkdownElement] = []

// AFTER:
var customElements: [any CDMarkdownElement] = []
var defaultElements: [any CDMarkdownElement] = []
```

Do not add `any` to `protocol CDMarkdownElement` declarations or `: CDMarkdownElement` conformance clauses — only to use sites.

---

**1.4 — Fix actor isolation diagnostics in `CDMarkdownParser`** ✅

`CDMarkdownParser` is `@MainActor`. Under Swift 6, all access to its properties and methods from non-isolated contexts is an error. The most common pattern to fix:

*Async call sites in tests* — If any test calls `parser.parse(_:)` without `await`, add `await`. The Swift Testing framework runs tests on the main actor by default, so most tests should compile without changes. For any test that uses a detached task or background actor, wrap calls:

```swift
let result = await MainActor.run { parser.parse(input) }
```

*`CDMarkdownImage.placeholderOnly`* — This internal property is set by `CDMarkdownParser` before parsing begins. Since `CDMarkdownParser` is `@MainActor` and `CDMarkdownImage` is not, this is a cross-actor write under Swift 6. Fix by either:
- Marking `CDMarkdownImage` as `@MainActor` (simplest), or
- Passing the flag as a parameter to `match(_:attributedString:)` instead of storing it

The simpler fix is to mark `CDMarkdownImage` `@MainActor`:

```swift
@MainActor
open class CDMarkdownImage: CDMarkdownLinkElement, CDMarkdownStyle {
```

---

**1.5 — Remove the `ExistentialAny` upcoming feature flag** ✅

After fixing all existential uses in step 1.3, the explicit `.enableUpcomingFeature("ExistentialAny")` in `Package.swift` is redundant — Swift 6 mode enforces it unconditionally. Remove it from `swiftSettings`:

```swift
// BEFORE:
swiftSettings: [
    .enableUpcomingFeature("ExistentialAny")
]
```

```swift
// AFTER:
// (remove swiftSettings entirely if ExistentialAny was the only entry)
```

If other upcoming feature flags were added, keep those and remove only `ExistentialAny`.

---

**1.6 — Update CI to verify Swift 6 mode** ✅

In `.github/workflows/ci.yml`, the SPM job already runs `swift build` and `swift test`. No changes are needed there. However, add a comment to the SPM job for clarity:

```yaml
- name: Build (Swift 6 mode)
  run: set -o pipefail && swift build 2>&1 | xcbeautify --renderer github-actions
- name: Test (Swift 6 mode)
  run: set -o pipefail && swift test -c debug 2>&1 | xcbeautify --renderer github-actions
```

---

**1.7 — Verify** ✅

Run the full check suite:

1. `swift build` — zero errors, zero warnings
2. `swift test` — all tests pass
3. `swiftlint lint --strict` — no violations
4. `swiftformat Source Tests --lint` — no formatting changes needed

---

## 2. Missing GFM Features

Three GFM features are absent from CDMarkdownKit: task lists, horizontal rules, and inline markdown inside table cells. Each is a self-contained parser change with no rendering stack dependency.

**Prerequisite**: None. Section 1 is recommended first but not required.

---

### Feature 1 — Task Lists

GitHub Flavored Markdown supports task list items: `- [ ] unchecked` and `- [x] checked`. These render as checkbox-like indicators before the item text. CDMarkdownKit's `CDMarkdownList` handles the bullet (`-`) but ignores the `[ ]` / `[x]` syntax.

---

**2.1 — Create `Source/CDMarkdownTaskList.swift`** ✅

Task list items are a specialization of unordered list items. The element conforms to `CDMarkdownElement` and `CDMarkdownStyle` directly (not `CDMarkdownLevelElement`) because the level/depth mechanism in `CDMarkdownLevelElement` is not needed — task items are always single-level.

```swift
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownTaskList: CDMarkdownElement, CDMarkdownStyle {

    // Matches: optional whitespace, list marker (- * +), space, [ ] or [x/X], space, content
    // Group 1: full leading whitespace + marker
    // Group 2: checkbox content (space = unchecked, x/X = checked)
    // Group 3: item text
    fileprivate static let regex = "^([ \\t]*[-*+][ \\t]+)\\[([  xX])\\][ \\t]+(.+)$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    /// The string used to represent an unchecked item. Default: "☐ "
    open var uncheckedMarker: String = "☐ "
    /// The string used to represent a checked item. Default: "☑ "
    open var checkedMarker: String = "☑ "

    open var regex: String {
        return CDMarkdownTaskList.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 2
            style.paragraphSpacingBefore = 0
            style.firstLineHeadIndent = 0
            style.lineSpacing = 1.0
            self.paragraphStyle = style
        }
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange     = match.nsRange(atIndex: 0)
        let markerRange   = match.nsRange(atIndex: 1)  // "- " or "* " etc.
        let checkboxRange = match.nsRange(atIndex: 2)  // " " or "x"
        let contentRange  = match.nsRange(atIndex: 3)  // item text

        let nsString = attributedString.string as NSString
        let checkboxValue = nsString.substring(with: checkboxRange).trimmingCharacters(in: .whitespaces)
        let isChecked = checkboxValue.lowercased() == "x"
        let replacement = isChecked ? checkedMarker : uncheckedMarker

        // Apply style to the content text
        attributedString.addAttributes(attributes, range: contentRange)

        // Compute headIndent so wrapped lines align under item text
        let markerWidth = replacement.sizeWithAttributes(attributes).width
        let updatedStyle = (paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        updatedStyle.headIndent = markerWidth
        attributedString.addParagraphStyle(updatedStyle, toRange: fullRange)

        // Replace the entire "- [ ] " prefix with the checkbox marker.
        // Build the replacement range: markerRange through the end of the checkbox syntax.
        // The checkbox syntax ends at contentRange.location - 1 (the space before content).
        let prefixRange = NSRange(location: markerRange.location,
                                  length: contentRange.location - markerRange.location)
        attributedString.replaceCharacters(in: prefixRange, with: replacement)
    }
}
```

---

**2.2 — Register `CDMarkdownTaskList` in `CDMarkdownParser`** ✅

Open `Source/CDMarkdownParser.swift`.

*Step 1* — Add a property in the `// MARK: - Basic Elements` block, immediately after the `orderedList` property:

```swift
public let taskList: CDMarkdownTaskList
```

*Step 2* — Initialize it in `init`, immediately after the `orderedList` initialization:

```swift
taskList = CDMarkdownTaskList(font: font,
                              color: fontColor,
                              backgroundColor: backgroundColor,
                              paragraphStyle: paragraphStyle)
```

*Step 3* — Insert `taskList` into `defaultElements` immediately **before** `list`. Task list items must be matched before the plain list element, because `CDMarkdownList` will also match `- [ ] item` (treating it as a bullet with `[ ] item` as text) and consume it first if given the chance:

```swift
// BEFORE:
self.defaultElements = [table, header, list, orderedList, quote, ...]
// AFTER:
self.defaultElements = [table, header, taskList, list, orderedList, quote, ...]
```

Apply this change to both the iOS/macOS/tvOS/visionOS branch and the watchOS branch.

---

**2.3 — Write tests in `Tests/CDMarkdownKitTests/Elements/CDMarkdownTaskListTests.swift`** ✅

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownTaskListTests {

    let parser = CDMarkdownParser()

    @Test func uncheckedItemRendersUncheckedMarker() {
        let result = parser.parse("- [ ] Buy milk")
        #expect(result.string.hasPrefix("☐ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemRendersCheckedMarker() {
        let result = parser.parse("- [x] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
        #expect(result.string.contains("Buy milk"))
    }

    @Test func checkedItemUppercaseX() {
        let result = parser.parse("- [X] Buy milk")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func asteriskMarkerSupported() {
        let result = parser.parse("* [ ] Task")
        #expect(result.string.hasPrefix("☐ "))
    }

    @Test func plusMarkerSupported() {
        let result = parser.parse("+ [x] Done")
        #expect(result.string.hasPrefix("☑ "))
    }

    @Test func plainListItemNotConsumed() {
        // A plain bullet without checkbox syntax must still be handled by CDMarkdownList
        let result = parser.parse("- plain item")
        #expect(!result.string.hasPrefix("☐"))
        #expect(!result.string.hasPrefix("☑"))
    }

    @Test func multipleTaskItems() {
        let input = "- [ ] First\n- [x] Second\n- [ ] Third"
        let result = parser.parse(input)
        #expect(result.string.contains("☐"))
        #expect(result.string.contains("☑"))
    }

    @Test func hasHeadIndent() {
        let result = parser.parse("- [ ] Item with a long enough text to wrap")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func customMarkerStrings() {
        let parser = CDMarkdownParser()
        parser.taskList.uncheckedMarker = "[ ] "
        parser.taskList.checkedMarker = "[x] "
        let result = parser.parse("- [ ] Item")
        #expect(result.string.hasPrefix("[ ] "))
    }
}
```

---

**2.4 — Verify** ✅

Run `swift build` and `swift test`. All existing tests must continue to pass.

---

### Feature 2 — Horizontal Rules

A horizontal rule (`---`, `***`, or `___`, optionally with spaces between characters) is a block-level element that CDMarkdownKit currently ignores entirely — the raw syntax passes through as plain text. This adds `CDMarkdownHorizontalRule`, which replaces the markdown syntax with a Unicode em-dash line or a configurable separator string.

---

**2.5 — Create `Source/CDMarkdownHorizontalRule.swift`** ✅

```swift
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownHorizontalRule: CDMarkdownElement, CDMarkdownStyle {

    // Matches a line containing only 3+ dashes, asterisks, or underscores,
    // optionally with spaces between them, with optional surrounding whitespace.
    // Groups: group 1 = entire matched content (used to determine which character was used)
    fileprivate static let regex = "^[ \\t]*([-*_])(?:[ \\t]*\\1){2,}[ \\t]*$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    /// The string that replaces the markdown horizontal rule syntax.
    /// Default: "\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}\u{2015}"  (8 em dashes)
    open var separatorString: String = "────────"

    open var regex: String {
        return CDMarkdownHorizontalRule.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        let fullRange = match.nsRange(atIndex: 0)
        attributedString.replaceCharacters(in: fullRange, with: separatorString)
        let replacedRange = NSRange(location: fullRange.location,
                                    length: (separatorString as NSString).length)
        attributedString.addAttributes(attributes, range: replacedRange)
    }
}
```

**Note on `separatorString`**: The default uses box-drawing characters (`─`) which render consistently in most system fonts. An alternative is `"—————————"` (em dashes) or a custom string set by the caller. The character chosen does not affect layout — it is treated as plain text by `NSAttributedString`.

---

**2.6 — Register `CDMarkdownHorizontalRule` in `CDMarkdownParser`** ✅

Open `Source/CDMarkdownParser.swift`.

*Step 1* — Add a property in the `// MARK: - Basic Elements` block:

```swift
public let horizontalRule: CDMarkdownHorizontalRule
```

*Step 2* — Initialize it in `init`:

```swift
horizontalRule = CDMarkdownHorizontalRule(font: font,
                                          color: fontColor,
                                          backgroundColor: backgroundColor,
                                          paragraphStyle: paragraphStyle)
```

*Step 3* — Insert `horizontalRule` into `defaultElements` immediately after `table` and before `header`. Horizontal rules must be matched early so that `---` inside a table separator row is not double-processed (the table element will have already consumed multi-column separators; single-column `---` can fall through to the horizontal rule):

```swift
// BEFORE:
self.defaultElements = [table, header, taskList, list, orderedList, quote, ...]
// AFTER:
self.defaultElements = [table, horizontalRule, header, taskList, list, orderedList, quote, ...]
```

Apply to both platform branches.

---

**2.7 — Write tests in `Tests/CDMarkdownKitTests/Elements/CDMarkdownHorizontalRuleTests.swift`** ✅

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownHorizontalRuleTests {

    let parser = CDMarkdownParser()

    @Test func dashSyntaxReplaced() {
        let result = parser.parse("---")
        #expect(!result.string.contains("-"))
        #expect(result.length > 0)
    }

    @Test func asteriskSyntaxReplaced() {
        let result = parser.parse("***")
        #expect(!result.string.contains("*"))
    }

    @Test func underscoreSyntaxReplaced() {
        let result = parser.parse("___")
        #expect(!result.string.contains("_"))
    }

    @Test func spacedDashesSyntaxReplaced() {
        let result = parser.parse("- - -")
        #expect(!result.string.contains("-"))
    }

    @Test func fiveOrMoreCharactersAllowed() {
        let result = parser.parse("-----")
        #expect(!result.string.contains("-"))
    }

    @Test func twoDashesNotHorizontalRule() {
        // Two characters should NOT match (requires 3+)
        let result = parser.parse("--")
        #expect(result.string.contains("-"))
    }

    @Test func contentBeforeIsPreserved() {
        let input = "Above\n---\nBelow"
        let result = parser.parse(input)
        #expect(result.string.contains("Above"))
        #expect(result.string.contains("Below"))
    }

    @Test func customSeparatorString() {
        let parser = CDMarkdownParser()
        parser.horizontalRule.separatorString = "---"
        let result = parser.parse("***")
        #expect(result.string.contains("---"))
    }
}
```

---

**2.8 — Verify** ✅

Run `swift build` and `swift test`. All existing tests must pass.

---

### Feature 3 — Inline Markdown in Table Cells

As noted in IMPLEMENTATION.md section 11.5: "This first implementation treats cell content as plain text. Inline formatting within cells (bold, italic, links) is not supported." This feature extends `CDMarkdownTable` to parse inline markdown within each cell.

**Design note**: Rather than making `CDMarkdownTable` aware of the full element pipeline (which would create a circular dependency with `CDMarkdownParser`), the table's `match()` method will accept an optional closure that applies inline parsing to a string. `CDMarkdownParser` passes itself in via this closure during initialization.

---

**2.9 — Add an inline-parsing closure to `CDMarkdownTable`** ✅

Open `Source/CDMarkdownTable.swift`.

*Step 1* — Add an internal property to store the inline parser:

```swift
/// Called on each cell's text content to apply inline element parsing (bold, italic, links, etc.).
/// Set by CDMarkdownParser during initialization. Nil means cells render as plain text.
internal var inlineParser: ((String) -> NSAttributedString)?
```

*Step 2* — In the `appendRow(_:cellAttributes:)` helper inside `match(_:attributedString:)`, replace the plain `NSAttributedString(string: text, attributes: cellAttributes)` construction with:

```swift
func appendRow(_ cells: [String], isBold: Bool) {
    let rowString = NSMutableAttributedString()
    for i in 0..<columnCount {
        if i > 0 {
            rowString.append(NSAttributedString(string: "\t"))
        }
        let text = i < cells.count ? cells[i] : ""
        let cellContent: NSAttributedString
        if let inlineParser = inlineParser, !text.isEmpty {
            // Parse inline markdown in cell content, then overlay the cell's paragraph style
            let parsed = NSMutableAttributedString(attributedString: inlineParser(text))
            if isBold {
                // Bold the header row if no explicit font was set by inline parsing
                parsed.enumerateAttribute(.font,
                                          in: NSRange(location: 0, length: parsed.length)) { value, range, _ in
                    if let font = value as? CDFont {
                        parsed.addAttribute(.font, value: font.bold(), range: range)
                    }
                }
            }
            cellContent = parsed
        } else {
            let cellAttributes = isBold ? boldAttributes : attributes
            cellContent = NSAttributedString(string: text, attributes: cellAttributes)
        }
        rowString.append(cellContent)
    }
    rowString.append(NSAttributedString(string: "\n"))
    let rowRange = NSRange(location: 0, length: rowString.length)
    rowString.addAttribute(.paragraphStyle, value: tableStyle, range: rowRange)
    result.append(rowString)
}

appendRow(headerCells, isBold: true)
for row in dataRows {
    appendRow(row, isBold: false)
}
```

*Step 3* — Remove the old `appendRow` and `boldAttributes` helpers and the two old `appendRow(headerCells, cellAttributes:)` and `appendRow(row, cellAttributes:)` call sites. The new version above replaces them.

---

**2.10 — Wire the inline parser from `CDMarkdownParser`** ✅

Open `Source/CDMarkdownParser.swift`.

In `init`, after creating the `table` element, set its inline parser closure. The closure must capture a weak reference to `self` to avoid a retain cycle, and call the synchronous inline-only parse (no image resolution, no table re-entry):

```swift
// Wire inline parsing for table cells after all elements are initialized
table.inlineParser = { [weak self] cellText in
    guard let self = self else { return NSAttributedString(string: cellText) }
    return self.parseInline(cellText)
}
```

Add a private `parseInline(_:)` method to `CDMarkdownParser` that runs only the inline elements (bold, italic, code, strikethrough, link, automatic link — not table, header, list, quote, or horizontal rule, to prevent recursion and block-element interference):

```swift
private func parseInline(_ string: String) -> NSAttributedString {
    let mutableString = NSMutableAttributedString(string: string,
                                                   attributes: [.font: font as AnyObject,
                                                                 .foregroundColor: fontColor as AnyObject])
    let inlineElements: [any CDMarkdownElement] = [
        codeEscaping, escaping,        // Phase 1
        link, automaticLink,           // Phase 2 inline
        bold, italic, strikethrough,   // Phase 2 inline
        code, unescaping               // Phase 3
    ]
    for element in inlineElements {
        element.parse(mutableString)
    }
    return mutableString
}
```

**Note**: `codeEscaping`, `escaping`, and `unescaping` must be included so that backtick-wrapped content inside a table cell is handled correctly. Ensure these element instances are stored as properties on `CDMarkdownParser` (they already are; verify their property names in the existing source).

---

**2.11 — Update tests in `Tests/CDMarkdownKitTests/Elements/CDMarkdownTableTests.swift`** ✅

Add new test cases to the existing `CDMarkdownTableTests` suite:

```swift
@Test func tableCellWithBoldContent() {
    let input = """
        | Header |
        | ------ |
        | **bold text** |
        """
    let result = parser.parse(input)
    var foundBold = false
    // Skip the header row (first line) and look at data rows
    result.enumerateAttribute(.font,
                              in: NSRange(location: 0, length: result.length)) { value, _, _ in
        if let font = value as? CDFont, font.isBold { foundBold = true }
    }
    // Header is always bold; confirm data cell bold is also present
    #expect(foundBold)
}

@Test func tableCellWithItalicContent() {
    let input = """
        | Header |
        | ------ |
        | *italic text* |
        """
    let result = parser.parse(input)
    var foundItalic = false
    result.enumerateAttribute(.font,
                              in: NSRange(location: 0, length: result.length)) { value, _, _ in
        if let font = value as? CDFont, font.isItalic { foundItalic = true }
    }
    #expect(foundItalic)
}

@Test func tableCellWithLinkContent() {
    let input = """
        | Header |
        | ------ |
        | [GitHub](https://github.com) |
        """
    let result = parser.parse(input)
    var foundLink = false
    result.enumerateAttribute(.link,
                              in: NSRange(location: 0, length: result.length)) { value, _, _ in
        if value != nil { foundLink = true }
    }
    #expect(foundLink)
}

@Test func tableCellWithInlineCode() {
    let input = """
        | Header |
        | ------ |
        | `code` |
        """
    let result = parser.parse(input)
    // Inline code should have monospace font
    var foundCode = false
    result.enumerateAttribute(.font,
                              in: NSRange(location: 0, length: result.length)) { value, _, _ in
        if let font = value as? CDFont,
           font.fontName.lowercased().contains("menlo") || font.fontName.lowercased().contains("courier") {
            foundCode = true
        }
    }
    #expect(foundCode)
}
```

---

**2.12 — Verify** ✅

Run `swift build` and `swift test`. All tests must pass. Manually verify in the Example app that a table with `**bold**` and `*italic*` cell content renders with proper styling.

---

## 3. API Ergonomics

Three usability gaps in the `CDMarkdownParser` public API: no way to disable individual default elements, custom elements always run after all built-in elements and cannot be inserted at a specific position, and the synchronous `parse(_:)` overload has no deprecation signal despite an async version existing.

**Prerequisite**: None. Best done before SwiftUI wrappers (Section 6) so the SwiftUI API surfaces the improved parser interface.

---

### Steps

**3.1 — Add `disabledElements` to `CDMarkdownParser`** ✅

Callers currently cannot opt out of individual default elements (e.g., disable automatic link detection without setting `automaticLinkDetectionEnabled = false`, which is a separate flag and does not exist for other elements). Add a general exclusion mechanism.

Open `Source/CDMarkdownParser.swift`.

*Step 1* — Add a public stored property:

```swift
/// Element types listed here are excluded from the parsing pipeline.
/// Use this to opt out of specific default elements without subclassing.
///
/// Example — disable header parsing:
/// ```swift
/// parser.disabledElementTypes.insert(ObjectIdentifier(CDMarkdownHeader.self))
/// ```
open var disabledElementTypes: Set<ObjectIdentifier> = []
```

*Step 2* — Add a convenience method so callers don't need to construct `ObjectIdentifier` manually:

```swift
/// Disables all default elements of the given type.
public func disable<T: AnyObject>(_ elementType: T.Type) {
    disabledElementTypes.insert(ObjectIdentifier(elementType))
}

/// Re-enables all default elements of the given type.
public func enable<T: AnyObject>(_ elementType: T.Type) {
    disabledElementTypes.remove(ObjectIdentifier(elementType))
}
```

*Step 3* — In the internal `parse(_:loadImages:)` method, filter `defaultElements` before iterating:

```swift
let activeElements = defaultElements.filter { element in
    !disabledElementTypes.contains(ObjectIdentifier(type(of: element)))
}
// Use activeElements instead of defaultElements in the Phase 2 loop
```

---

**3.2 — Add `insertCustomElement(_:before:)` and `insertCustomElement(_:after:)`** ✅

Currently `customElements` is a plain array and custom elements always run after all default elements. Add insertion helpers that allow positioning relative to a specific default element type.

Open `Source/CDMarkdownParser.swift`.

Add two public methods:

```swift
/// Inserts a custom element into the pipeline immediately before all default elements of `elementType`.
/// If no default element of that type exists, the custom element is appended to `customElements`.
public func insertCustomElement(_ element: any CDMarkdownElement,
                                 before elementType: (some AnyObject).Type) {
    let targetID = ObjectIdentifier(elementType)
    if let index = defaultElements.firstIndex(where: { ObjectIdentifier(type(of: $0)) == targetID }) {
        defaultElements.insert(element, at: index)
    } else {
        customElements.append(element)
    }
}

/// Inserts a custom element into the pipeline immediately after all default elements of `elementType`.
/// If no default element of that type exists, the custom element is appended to `customElements`.
public func insertCustomElement(_ element: any CDMarkdownElement,
                                 after elementType: (some AnyObject).Type) {
    let targetID = ObjectIdentifier(elementType)
    if let index = defaultElements.lastIndex(where: { ObjectIdentifier(type(of: $0)) == targetID }) {
        defaultElements.insert(element, at: index + 1)
    } else {
        customElements.append(element)
    }
}
```

**Note**: This changes `defaultElements` from a `let` to a `var` if it isn't already. Verify the property declaration and update it if needed.

---

**3.3 — Deprecate the synchronous `parse(_:)` overloads** ✅

The synchronous `parse(_:)` family was the original API. IMPLEMENTATION.md section 8 added async overloads. Now that async is available, mark the sync overloads as soft-deprecated to guide new callers toward async while maintaining full backward compatibility.

Open `Source/CDMarkdownParser.swift`. Find each synchronous `public func parse(` overload and add a deprecation annotation:

```swift
@available(*, deprecated, renamed: "parse(_:)")
public func parse(_ string: String) -> NSAttributedString {
    // ... existing implementation unchanged ...
}
```

**Important**: Swift allows two methods with the same name that differ only by `async`. The deprecation message `renamed: "parse(_:)"` points callers at the async overload of the same name. Do not change the method body — only add the `@available` attribute.

Apply the same annotation to the `NSAttributedString` overload:

```swift
@available(*, deprecated, renamed: "parse(_:)")
public func parse(_ attributedString: NSAttributedString) -> NSAttributedString {
```

---

**3.4 — Write tests for `disabledElementTypes`** ✅

Add a new test file `Tests/CDMarkdownKitTests/Parser/CDMarkdownParserDisabledElementTests.swift`:

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownParserDisabledElementTests {

    @Test func disabledHeaderProducesNoLargeFont() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownHeader.self)
        let result = parser.parse("# Heading")
        var foundLargeFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 { foundLargeFont = true }
        }
        #expect(!foundLargeFont)
        #expect(result.string.contains("#")) // raw syntax passes through
    }

    @Test func disabledBoldProducesNoBold() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownBold.self)
        let result = parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func reenablingElementRestoresBehavior() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownBold.self)
        parser.enable(CDMarkdownBold.self)
        let result = parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(foundBold)
    }

    @Test func disablingNonexistentTypeIsNoop() {
        let parser = CDMarkdownParser()
        parser.disable(CDMarkdownOrderedList.self)
        parser.disable(CDMarkdownOrderedList.self) // duplicate is safe
        let result = parser.parse("1. Item")
        #expect(result.string.contains("1."))
    }
}
```

---

**3.5 — Write tests for `insertCustomElement(_:before/after:)`** ✅

Add to `Tests/CDMarkdownKitTests/Parser/CDMarkdownParserTests.swift` or a new `CDMarkdownParserInsertionTests.swift`:

```swift
@Suite struct CDMarkdownParserInsertionTests {

    @Test func insertBeforeKnownElementPositionsCorrectly() {
        // Inserting a no-op custom element before CDMarkdownBold should not break bold parsing
        let parser = CDMarkdownParser()
        let noOpElement = CDMarkdownBold() // reuse as a stand-in
        parser.insertCustomElement(noOpElement, before: CDMarkdownItalic.self)
        let result = parser.parse("**bold**")
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(foundBold)
    }

    @Test func insertBeforeUnknownElementFallsBackToAppend() {
        let parser = CDMarkdownParser()
        class UnknownElement: CDMarkdownBold {}
        let element = CDMarkdownBold()
        let countBefore = parser.customElements.count
        parser.insertCustomElement(element, before: UnknownElement.self)
        #expect(parser.customElements.count == countBefore + 1)
    }
}
```

---

**3.6 — Update `Documentation/Usage.md`** ✅

In `Documentation/Usage.md`, add a section under "CDMarkdownParser" titled **"Customizing the element pipeline"**:

```markdown
## Customizing the Element Pipeline

### Disabling default elements

```swift
let parser = CDMarkdownParser()
parser.disable(CDMarkdownHeader.self)       // raw # syntax passes through
parser.disable(CDMarkdownAutomaticLink.self) // no automatic URL detection
```

Re-enable at any time:

```swift
parser.enable(CDMarkdownHeader.self)
```

### Inserting custom elements at specific positions

By default, custom elements run after all built-in elements. Use `insertCustomElement(_:before:)` or `insertCustomElement(_:after:)` to position them precisely:

```swift
let mention = CDMarkdownMention()
parser.insertCustomElement(mention, before: CDMarkdownBold.self)
```

### Async vs. synchronous parsing

Prefer the async overload for all new code:

```swift
let attributed = await parser.parse("Hello **world**")
```

The synchronous `parse(_:)` overloads are deprecated and will be removed in a future major version. They remain available for backward compatibility.

---

**3.7 — Verify** ✅

Run `swift build` and `swift test`. All existing tests must pass alongside the new ones. Confirm the deprecation warning appears in Xcode when calling `parser.parse("...")` without `await`.

---

## 4. Accessibility

CDMarkdownKit applies `NSAttributedString` attributes for visual styling but adds nothing for assistive technologies. VoiceOver and other AT read back the stripped text content but have no signal that a span is a heading, a code block, or a link with a custom URL scheme. This section adds accessibility annotations at the `NSAttributedString` level — no rendering stack changes are required.

**Prerequisite**: None.

---

### Steps

**4.1 — Define accessibility attribute keys** ✅

Open `Source/CDAttributedStringKey.swift` (or `Source/NSAttributedString.Key+CDMarkdownKit.swift` — whichever file holds the custom key extensions added in IMPLEMENTATION.md section 5).

Add the following keys:

```swift
extension NSAttributedString.Key {
    /// Applied to heading ranges. Value: `Int` (1–6 corresponding to H1–H6).
    static let cdMarkdownHeadingLevel = NSAttributedString.Key("CDMarkdownKit.headingLevel")

    /// Applied to inline code and fenced code block ranges. Value: `true as AnyObject`.
    /// Distinct from `.cdMarkdownRoundedBackground` — that key drives drawing; this drives AT.
    static let cdMarkdownIsCode = NSAttributedString.Key("CDMarkdownKit.isCode")

    /// Applied to blockquote ranges. Value: `true as AnyObject`.
    static let cdMarkdownIsBlockquote = NSAttributedString.Key("CDMarkdownKit.isBlockquote")
}
```

---

**4.2 — Write heading level into `CDMarkdownHeader`** ✅

Open `Source/CDMarkdownHeader.swift`. In the `match(_:attributedString:)` method (or `addAttributes(_:range:level:)` if it exists), after applying existing attributes, also write the heading level:

```swift
attributedString.addAttribute(.cdMarkdownHeadingLevel,
                               value: level as AnyObject,
                               range: range)
```

`level` is available from `CDMarkdownLevelElement.match()` — it's derived from `match.range(at: 1).length`. Confirm the variable name in the existing `CDMarkdownHeader` source.

---

**4.3 — Write code flag into `CDMarkdownCode` and `CDMarkdownSyntax`** ✅

Open `Source/CDMarkdownCode.swift`. In `addAttributes(_:range:)`, after applying existing attributes:

```swift
attributedString.addAttribute(.cdMarkdownIsCode,
                               value: true as AnyObject,
                               range: range)
```

Open `Source/CDMarkdownSyntax.swift`. Apply the same addition in its `addAttributes(_:range:)` override.

---

**4.4 — Write blockquote flag into `CDMarkdownQuote`** ✅

Open `Source/CDMarkdownQuote.swift`. In `match(_:attributedString:)`, after applying existing attributes to the content range:

```swift
attributedString.addAttribute(.cdMarkdownIsBlockquote,
                               value: true as AnyObject,
                               range: contentRange)
```

Confirm the variable name for the content range in the existing source.

---

**4.5 — Add an `accessibilityAttributedString(from:)` helper to `CDMarkdownParser`** ✅

This method converts the parsed `NSAttributedString` (which has CDMarkdownKit's custom attributes) into one that uses standard `NSAccessibilityAttributedStringKey` annotations understood by VoiceOver. This is a separate pass so callers who do not need accessibility do not pay the cost.

Add to `Source/CDMarkdownParser.swift`:

```swift
/// Returns a copy of the attributed string with VoiceOver-compatible accessibility
/// annotations derived from CDMarkdownKit's custom attributes.
///
/// Pass the result to `UILabel.accessibilityAttributedLabel` or
/// `UITextView.accessibilityAttributedLabel`.
public func accessibilityAttributedString(from attributedString: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: attributedString)
    let fullRange = NSRange(location: 0, length: result.length)

    // Map heading levels to UIAccessibilityTextAttributeHeadingLevel
    result.enumerateAttribute(.cdMarkdownHeadingLevel, in: fullRange) { value, range, _ in
        guard let level = value as? Int else { return }
        // UIAccessibility heading levels: 1 (highest) to 6 (lowest)
        result.addAttribute(NSAttributedString.Key(UIAccessibility.textAttributeHeadingLevel),
                             value: level as AnyObject,
                             range: range)
    }

    return result
}
```

**Platform note**: `UIAccessibility.textAttributeHeadingLevel` is iOS/tvOS/visionOS only. Wrap with `#if os(iOS) || os(tvOS) || os(visionOS)`. On macOS, `NSAccessibilityAttributedStringKey` provides `NSAccessibilityMarkedMisspelledTextAttribute` and similar but no direct heading-level equivalent — on macOS, emit a `NSAccessibilityRoleAttribute` for headings instead if available.

Full implementation:

```swift
#if os(iOS) || os(tvOS) || os(visionOS)
public func accessibilityAttributedString(from attributedString: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: attributedString)
    let fullRange = NSRange(location: 0, length: result.length)

    result.enumerateAttribute(.cdMarkdownHeadingLevel, in: fullRange) { value, range, _ in
        guard let level = value as? Int else { return }
        result.addAttribute(NSAttributedString.Key(UIAccessibility.textAttributeHeadingLevel),
                             value: level as AnyObject,
                             range: range)
    }

    return result
}
#endif
```

---

**4.6 — Update `CDMarkdownLabel` to apply accessibility annotations automatically** ✅

Open `Source/CDMarkdownLabel.swift`. `CDMarkdownLabel` is the primary display component for read-only markdown text. After setting `attributedText`, also set `accessibilityAttributedLabel` if a parser is available:

Find the `parseTextAndExtractURLRanges(_:)` method (or wherever `attributedText` is assigned). After the assignment, add:

```swift
if let parser = markdownParser {
    accessibilityAttributedLabel = parser.accessibilityAttributedString(from: attrString)
}
```

This requires that `CDMarkdownLabel` holds a reference to its `CDMarkdownParser`. Check the existing `CDMarkdownLabel` source — if the parser is not already a stored property, add:

```swift
/// The parser used to render markdown text. Set this before assigning `parseText`.
public weak var markdownParser: CDMarkdownParser?
```

and update the label's `parseText` setter to use `markdownParser?.parse(newValue)` if not already doing so.

---

**4.7 — Document accessibility in `Usage.md`** ✅

Add a section "Accessibility" to `Documentation/Usage.md`:

```markdown
## Accessibility

CDMarkdownKit writes semantic metadata (heading level, code, blockquote) as custom
`NSAttributedString` attributes during parsing. These are automatically mapped to
VoiceOver-compatible annotations by `CDMarkdownLabel`.

For `CDMarkdownTextView` or custom views, apply annotations manually:

```swift
let attributed = await parser.parse(markdown)
textView.attributedText = attributed
textView.accessibilityAttributedLabel = parser.accessibilityAttributedString(from: attributed)
```

VoiceOver will announce headings with their level ("Heading level 1: Introduction"),
helping users navigate document structure with the rotor.

---

**4.8 — Write tests in `Tests/CDMarkdownKitTests/Features/AccessibilityTests.swift`** ✅

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct AccessibilityTests {

    let parser = CDMarkdownParser()

    @Test func headingWritesHeadingLevelAttribute() {
        let result = parser.parse("# Heading One")
        var foundLevel: Int?
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let level = value as? Int { foundLevel = level }
        }
        #expect(foundLevel == 1)
    }

    @Test func h3WritesLevel3() {
        let result = parser.parse("### Third Level")
        var foundLevel: Int?
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let level = value as? Int { foundLevel = level }
        }
        #expect(foundLevel == 3)
    }

    @Test func inlineCodeWritesCodeAttribute() {
        let result = parser.parse("`code`")
        var foundCode = false
        result.enumerateAttribute(.cdMarkdownIsCode,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundCode = true }
        }
        #expect(foundCode)
    }

    @Test func fencedCodeWritesCodeAttribute() {
        let result = parser.parse("```\ncode block\n```")
        var foundCode = false
        result.enumerateAttribute(.cdMarkdownIsCode,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundCode = true }
        }
        #expect(foundCode)
    }

    @Test func blockquoteWritesBlockquoteAttribute() {
        let result = parser.parse("> quote")
        var foundQuote = false
        result.enumerateAttribute(.cdMarkdownIsBlockquote,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundQuote = true }
        }
        #expect(foundQuote)
    }

    @Test func plainTextHasNoAccessibilityAttributes() {
        let result = parser.parse("Hello world")
        var found = false
        result.enumerateAttribute(.cdMarkdownHeadingLevel,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { found = true }
        }
        #expect(!found)
    }
}
```

---

**4.9 — Verify** ✅

Run `swift build` and `swift test`. Manually test in the Example app with VoiceOver enabled: navigate to a heading and confirm the VoiceOver rotor lists it as a heading. Confirm `CDMarkdownLabel` with heading content speaks the heading level.

---

## 5. macOS UI Components

CDMarkdownKit's parsing pipeline works on macOS but there are no AppKit UI components — no `NSTextView` or `NSTextField` subclass that handles rounded-corner backgrounds or link tap callbacks. This section adds `CDMarkdownNSTextView` (an `NSTextView` subclass) and `CDMarkdownNSLabel` (a lightweight `NSTextField` subclass for read-only display).

**Prerequisite**: None. Required before Section 6 (SwiftUI Wrappers) for full macOS SwiftUI support.

---

### Steps

**5.1 — Create `Source/CDMarkdownNSLayoutManager.swift`** ✅

macOS needs its own layout manager subclass that mirrors `CDMarkdownLayoutManager` but uses `NSColor` and AppKit drawing. Create this file gated on `#if os(macOS)`:

```swift
#if os(macOS)
import Cocoa

open class CDMarkdownNSLayoutManager: NSLayoutManager {

    open var roundAllCorners: Bool = false

    override open func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>,
                                               count rectCount: Int,
                                               forCharacterRange charRange: NSRange,
                                               color: NSColor) {
        guard roundAllCorners || hasRoundedAttribute(at: charRange) else {
            super.fillBackgroundRectArray(rectArray, count: rectCount,
                                          forCharacterRange: charRange, color: color)
            return
        }

        color.setFill()
        for i in 0..<rectCount {
            let rect = rectArray[i].insetBy(dx: 0, dy: 1)
            let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            path.fill()
        }
    }

    private func hasRoundedAttribute(at charRange: NSRange) -> Bool {
        guard charRange.location < (textStorage?.length ?? 0) else { return false }
        return textStorage?.attribute(.cdMarkdownRoundedBackground,
                                       at: charRange.location,
                                       effectiveRange: nil) as? Bool == true
    }
}
#endif
```

---

**5.2 — Create `Source/CDMarkdownNSTextView.swift`** ✅

```swift
#if os(macOS)
import Cocoa

/// A read-only `NSTextView` subclass that renders `NSAttributedString` output from
/// `CDMarkdownParser` with optional rounded-corner backgrounds for code spans.
@MainActor
open class CDMarkdownNSTextView: NSTextView {

    open var customLayoutManager: CDMarkdownNSLayoutManager!
    open var customTextStorage: NSTextStorage!

    open var roundAllCorners: Bool = false {
        didSet { customLayoutManager?.roundAllCorners = roundAllCorners }
    }

    // MARK: - Initializers

    public init(frame: NSRect) {
        super.init(frame: frame, textContainer: nil)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    open func configure() {
        // Replace the default layout manager with our custom one
        if let defaultLM = layoutManager {
            textStorage?.removeLayoutManager(defaultLM)
        }
        customLayoutManager = CDMarkdownNSLayoutManager()
        customTextStorage = NSTextStorage()
        customTextStorage.addLayoutManager(customLayoutManager)
        customLayoutManager.addTextContainer(textContainer!)
        isEditable = false
        isSelectable = true   // required for link clicks on macOS
    }

    // MARK: - Attributed Text

    open override var attributedString: NSAttributedString {
        get { return super.attributedString }
    }

    open func setAttributedString(_ attributedString: NSAttributedString) {
        customTextStorage.setAttributedString(attributedString)
        super.textStorage?.setAttributedString(attributedString)
    }
}
#endif
```

**Note on macOS link handling**: On macOS, `NSTextView` with `isSelectable = true` and `.link` attributes opens links via `NSWorkspace.shared.open(_:)` automatically. No delegate override is needed for the default behaviour. Callers who want to intercept links can set a delegate conforming to `NSTextViewDelegate.textView(_:clickedOnLink:at:)`.

---

**5.3 — Create `Source/CDMarkdownNSLabel.swift`** ✅

For simple read-only display without link interaction, an `NSTextField`-based label is lighter weight than a full `NSTextView`. However, `NSTextField` does not use `NSLayoutManager` and therefore cannot draw rounded corners. Use a custom `NSView` subclass instead, drawing text via `NSLayoutManager` directly (mirroring how `CDMarkdownLabel` works on iOS).

```swift
#if os(macOS)
import Cocoa

/// A lightweight read-only `NSView` subclass that renders `NSAttributedString` output from
/// `CDMarkdownParser`. Supports rounded-corner backgrounds for code spans via `NSLayoutManager`.
@MainActor
open class CDMarkdownNSLabel: NSView {

    // MARK: - Public Properties

    open var attributedText: NSAttributedString = NSAttributedString() {
        didSet {
            textStorage.setAttributedString(attributedText)
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }
    }

    open var roundAllCorners: Bool = false {
        didSet { layoutManager.roundAllCorners = roundAllCorners }
    }

    open var numberOfLines: Int = 0 {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }
    }

    // MARK: - Private Text Stack

    private let textStorage = NSTextStorage()
    private let layoutManager = CDMarkdownNSLayoutManager()
    private let textContainer = NSTextContainer()

    // MARK: - Initializers

    public override init(frame: NSRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
    }

    // MARK: - Layout

    open override var intrinsicContentSize: NSSize {
        textContainer.containerSize = NSSize(width: bounds.width,
                                             height: CGFloat.greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(usedRect.height))
    }

    open override func layout() {
        super.layout()
        textContainer.containerSize = NSSize(width: bounds.width,
                                             height: CGFloat.greatestFiniteMagnitude)
    }

    // MARK: - Drawing

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
    }
}
#endif
```

---

**5.4 — Add macOS UI files to the Xcode project** ✅

Open `CDMarkdownKit.xcodeproj`. In the macOS scheme target's **Build Phases → Compile Sources**, add:

- `CDMarkdownNSLayoutManager.swift`
- `CDMarkdownNSTextView.swift`
- `CDMarkdownNSLabel.swift`

These files are already gated on `#if os(macOS)` so including them in other targets is safe, but for cleanliness add them only to the macOS target. If the SPM package is the primary distribution path, no Xcode project changes are needed — SPM compiles all files in `Source/` and the `#if os(macOS)` guards do the right thing.

---

**5.5 — Write tests in `Tests/CDMarkdownKitTests/UI/CDMarkdownNSLabelTests.swift`** ✅

macOS UI tests require a running AppKit application loop, which is not available in a plain `swift test` run. Write smoke tests that exercise the layout stack without requiring display:

```swift
#if os(macOS)
import Testing
import Cocoa
@testable import CDMarkdownKit

@Suite struct CDMarkdownNSLabelTests {

    @Test func labelAcceptsAttributedText() {
        let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        let parser = CDMarkdownParser()
        label.attributedText = parser.parse("Hello **world**")
        #expect(label.attributedText.length > 0)
    }

    @Test func labelIntrinsicHeightIsPositive() {
        let label = CDMarkdownNSLabel(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        let parser = CDMarkdownParser()
        label.attributedText = parser.parse("Hello **world**")
        #expect(label.intrinsicContentSize.height > 0)
    }

    @Test func roundAllCornersFlag() {
        let label = CDMarkdownNSLabel(frame: .zero)
        label.roundAllCorners = true
        #expect(label.roundAllCorners == true)
    }
}
#endif
```

---

**5.6 — Update `Documentation/Usage.md`** ✅

Add a "macOS" section under "UI Components":

```markdown
## macOS UI Components

### CDMarkdownNSTextView

`CDMarkdownNSTextView` is a read-only `NSTextView` subclass with rounded-corner support
for code spans. Use it for rich display with selectable text and native link handling:

```swift
let textView = CDMarkdownNSTextView(frame: view.bounds)
textView.roundAllCorners = true
Task {
    textView.setAttributedString(await parser.parse(markdown))
}
```

Links in the attributed string are opened automatically by `NSWorkspace` when clicked.
To intercept link clicks, set a delegate:

```swift
textView.delegate = self  // NSTextViewDelegate

func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
    if let url = link as? URL, url.scheme == "mention" {
        // handle custom scheme
        return true
    }
    return false
}
```

### CDMarkdownNSLabel

`CDMarkdownNSLabel` is a lightweight read-only `NSView` for simple markdown display without
link interaction:

```swift
let label = CDMarkdownNSLabel(frame: .zero)
label.attributedText = parser.parse("Hello **world**")
```

---

**5.7 — Verify** ✅

Run `swift build` and `swift test`. Run the macOS Xcode scheme and manually verify:
- A `CDMarkdownNSTextView` displays markdown with correct styling
- Code spans have rounded corners when `roundAllCorners = true`
- Clicking a link opens it in the default browser
- `CDMarkdownNSLabel` renders text and has a non-zero intrinsic height

---

## 6. SwiftUI Wrappers

CDMarkdownKit has no SwiftUI-native API. This section adds two SwiftUI views: `CDMarkdownText` (a lightweight wrapper using SwiftUI's native `Text` with `AttributedString`) and `CDMarkdownView` (a full-fidelity wrapper using `UIViewRepresentable` / `NSViewRepresentable` for platforms that need rounded corners and link interaction).

**Prerequisites**: Section 5 (macOS UI Components) for full macOS `CDMarkdownView` support. Sections 3 and 4 are recommended so the SwiftUI API benefits from the improved parser and accessibility annotations.

---

### Steps

**6.1 — Create `Source/CDMarkdownText.swift`** ✅

`CDMarkdownText` uses SwiftUI's built-in `Text(attributedString:)` API (available iOS 15+). It is the simplest integration and works everywhere SwiftUI does, but does not support rounded-corner code backgrounds (a UIKit/AppKit drawing feature that SwiftUI's `Text` does not expose).

```swift
import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
public struct CDMarkdownText: View {

    private let string: String
    @State private var attributedString: AttributedString = AttributedString()
    private let parser: CDMarkdownParser

    /// Creates a view that renders `string` as Markdown using `parser`.
    public init(_ string: String, parser: CDMarkdownParser = CDMarkdownParser()) {
        self.string = string
        self.parser = parser
    }

    public var body: some View {
        Text(attributedString)
            .task(id: string) {
                let ns = await parser.parse(string)
                attributedString = (try? AttributedString(ns, including: \.uiKit)) ?? AttributedString(string)
            }
    }
}
```

**Platform note**: `AttributedString(_, including: \.uiKit)` is available on iOS 15+ / macOS 12+. On watchOS and tvOS use the same API — it is available on those platforms at the same versions. On macOS, use `\.appKit` instead of `\.uiKit`. Add a conditional:

```swift
#if os(macOS)
attributedString = (try? AttributedString(ns, including: \.appKit)) ?? AttributedString(string)
#else
attributedString = (try? AttributedString(ns, including: \.uiKit)) ?? AttributedString(string)
#endif
```

---

**6.2 — Create `Source/CDMarkdownView.swift`** ✅

`CDMarkdownView` wraps `CDMarkdownTextView` (iOS/tvOS/visionOS) or `CDMarkdownNSTextView` (macOS) in the appropriate `UIViewRepresentable` / `NSViewRepresentable`. This provides full fidelity — rounded corners, link interaction, and correct text layout — at the cost of bridging overhead.

```swift
import SwiftUI

// MARK: - iOS / tvOS / visionOS

#if os(iOS) || os(tvOS) || os(visionOS)
@available(iOS 15.0, tvOS 15.0, visionOS 1.0, *)
public struct CDMarkdownView: UIViewRepresentable {

    private let string: String
    private let parser: CDMarkdownParser
    public var onLinkTap: ((URL) -> Void)?

    /// Creates a full-fidelity Markdown view with rounded-corner support.
    public init(_ string: String,
                parser: CDMarkdownParser = CDMarkdownParser(),
                onLinkTap: ((URL) -> Void)? = nil) {
        self.string = string
        self.parser = parser
        self.onLinkTap = onLinkTap
    }

    public func makeUIView(context: Context) -> CDMarkdownTextView {
        let textView = CDMarkdownTextView.makeTextView(frame: .zero)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.isSelectable = true
        textView.delegate = context.coordinator
        return textView
    }

    public func updateUIView(_ uiView: CDMarkdownTextView, context: Context) {
        context.coordinator.onLinkTap = onLinkTap
        Task { @MainActor in
            uiView.attributedText = await parser.parse(string)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onLinkTap: onLinkTap)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var onLinkTap: ((URL) -> Void)?

        init(onLinkTap: ((URL) -> Void)?) {
            self.onLinkTap = onLinkTap
        }

        public func textView(_ textView: UITextView,
                             shouldInteractWith url: URL,
                             in characterRange: NSRange,
                             interaction: UITextItemInteraction) -> Bool {
            onLinkTap?(url)
            return onLinkTap == nil  // let UIKit handle if no custom handler
        }
    }
}

// MARK: - macOS

#elseif os(macOS)
@available(macOS 12.0, *)
public struct CDMarkdownView: NSViewRepresentable {

    private let string: String
    private let parser: CDMarkdownParser
    public var onLinkTap: ((URL) -> Bool)?

    /// Creates a full-fidelity Markdown view with rounded-corner support.
    public init(_ string: String,
                parser: CDMarkdownParser = CDMarkdownParser(),
                onLinkTap: ((URL) -> Bool)? = nil) {
        self.string = string
        self.parser = parser
        self.onLinkTap = onLinkTap
    }

    public func makeNSView(context: Context) -> CDMarkdownNSTextView {
        let textView = CDMarkdownNSTextView(frame: .zero)
        textView.delegate = context.coordinator
        return textView
    }

    public func updateNSView(_ nsView: CDMarkdownNSTextView, context: Context) {
        context.coordinator.onLinkTap = onLinkTap
        Task { @MainActor in
            nsView.setAttributedString(await parser.parse(string))
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onLinkTap: onLinkTap)
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var onLinkTap: ((URL) -> Bool)?

        init(onLinkTap: ((URL) -> Bool)?) {
            self.onLinkTap = onLinkTap
        }

        public func textView(_ textView: NSTextView,
                             clickedOnLink link: Any,
                             at charIndex: Int) -> Bool {
            if let url = link as? URL, let handler = onLinkTap {
                return handler(url)
            }
            return false
        }
    }
}
#endif
```

---

**6.3 — Create `Source/CDMarkdownEnvironmentKey.swift`** ✅

Allow a `CDMarkdownParser` to be injected via the SwiftUI environment, so deeply nested views can share a single configured parser without passing it explicitly at every call site.

```swift
import SwiftUI

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
private struct CDMarkdownParserKey: EnvironmentKey {
    static let defaultValue: CDMarkdownParser = CDMarkdownParser()
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension EnvironmentValues {
    /// The `CDMarkdownParser` used by `CDMarkdownText` and `CDMarkdownView`
    /// when no parser is provided explicitly.
    public var markdownParser: CDMarkdownParser {
        get { self[CDMarkdownParserKey.self] }
        set { self[CDMarkdownParserKey.self] = newValue }
    }
}
```

Update `CDMarkdownText` and `CDMarkdownView` to read from the environment if no explicit parser was provided. This requires a small refactor: make `parser` an `@Environment(\.markdownParser)` property when no parser was passed in. The cleanest way is to store the parser as an optional and fall back to the environment value:

In `CDMarkdownText`:

```swift
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
public struct CDMarkdownText: View {

    private let string: String
    private let explicitParser: CDMarkdownParser?
    @Environment(\.markdownParser) private var environmentParser
    @State private var attributedString: AttributedString = AttributedString()

    private var parser: CDMarkdownParser { explicitParser ?? environmentParser }

    public init(_ string: String, parser: CDMarkdownParser? = nil) {
        self.string = string
        self.explicitParser = parser
    }

    // body unchanged
}
```

Apply the same pattern to `CDMarkdownView`.

---

**6.4 — Add `View.markdownParser(_:)` modifier** ✅

Add a convenience modifier so callers don't need to know about `EnvironmentValues` directly:

```swift
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
extension View {
    /// Sets the `CDMarkdownParser` used by all `CDMarkdownText` and `CDMarkdownView`
    /// views in this subtree.
    public func markdownParser(_ parser: CDMarkdownParser) -> some View {
        environment(\.markdownParser, parser)
    }
}
```

Add this to `Source/CDMarkdownEnvironmentKey.swift`.

---

**6.5 — Write tests in `Tests/CDMarkdownKitTests/SwiftUI/CDMarkdownTextTests.swift`** ✅

SwiftUI view tests require `XCTest` + `ViewInspector` or a hosting environment. Since the project uses Swift Testing and has no third-party test dependencies, limit tests to verifiable non-rendering properties:

```swift
import Testing
import SwiftUI
@testable import CDMarkdownKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, visionOS 1.0, *)
@Suite struct CDMarkdownTextTests {

    @Test func cdMarkdownTextInitializesWithString() {
        let view = CDMarkdownText("Hello **world**")
        // Verify the view can be created without crashing
        #expect(type(of: view) == CDMarkdownText.self)
    }

    @Test func cdMarkdownTextAcceptsExplicitParser() {
        let parser = CDMarkdownParser()
        let view = CDMarkdownText("Hello", parser: parser)
        #expect(type(of: view) == CDMarkdownText.self)
    }

    @Test func environmentKeyDefaultValueIsNonNil() {
        var env = EnvironmentValues()
        let parser = env.markdownParser
        // Default parser should be usable
        let result = parser.parse("test")
        #expect(result.length > 0)
    }

    @Test func viewModifierSetsParser() {
        let customParser = CDMarkdownParser()
        let view = CDMarkdownText("test").markdownParser(customParser)
        #expect(type(of: view) != CDMarkdownText.self) // wrapped in modifier
    }
}
```

---

**6.6 — Update `Documentation/Usage.md`** ✅

Add a "SwiftUI" section:

```markdown
## SwiftUI

### CDMarkdownText

The lightweight option. Uses SwiftUI's `Text` with `AttributedString`. Does not draw
rounded-corner code backgrounds, but works everywhere SwiftUI does:

```swift
CDMarkdownText("Hello **world**")
```

### CDMarkdownView

Full fidelity, including rounded-corner code blocks and link interaction:

```swift
CDMarkdownView("Hello **world**\n\n`code`") { url in
    // handle link tap
    openURL(url)
}
```

### Sharing a parser

Set a parser once for a whole view hierarchy:

```swift
ContentView()
    .markdownParser(myParser)
```

Any `CDMarkdownText` or `CDMarkdownView` in the subtree will use `myParser` unless
overridden with an explicit `parser:` argument.
```

---

**6.7 — Update README badges and feature list**

In `README.md`, update the feature list to include:

```markdown
- [x] SwiftUI support via `CDMarkdownText` and `CDMarkdownView`
```

---

**6.8 — Verify**

Run `swift build` and `swift test`. Build the iOS, macOS, and tvOS Xcode schemes. In the Example app (or a new SwiftUI preview), verify:
- `CDMarkdownText` renders bold, italic, and links with correct styling
- `CDMarkdownView` renders code blocks with rounded corners
- A parser injected via `.markdownParser(_:)` is used by child `CDMarkdownText` views
- Link taps in `CDMarkdownView` trigger the `onLinkTap` closure
- On macOS, `CDMarkdownView` correctly wraps `CDMarkdownNSTextView`

---

## 7. Release v3.2.0

This section covers tagging and releasing v3.2.0. The release bundles all work from sections 1–6: Swift 6 language mode, task lists, horizontal rules, inline markdown in table cells, API ergonomics improvements, accessibility annotations, macOS UI components, and SwiftUI wrappers.

**Prerequisite**: Sections 1–6 must all be complete and all CI checks must be green before proceeding.

---

**7.1 — Bump the version**

Update the version constant in `Source/CDMarkdownKit.swift` from `"3.1.0"` to `"3.2.0"`:

```swift
public let CDMarkdownKitVersionNumber = "3.2.0"
```

---

**7.2 — Update `CDMarkdownKit.podspec`**

Change `s.version` from `'3.1.0'` to `'3.2.0'`:

```ruby
s.version = '3.2.0'
```

Verify the podspec lints cleanly:

```bash
bundle exec pod lib lint --allow-warnings
```

---

**7.3 — Write the CHANGELOG entry**

Add the `3.2.0` entry at the top of `CHANGELOG.md`, immediately above the `3.1.0` entry, and add `3.2.0` to the Table of Contents. Follow the format established in step 1.1 of IMPLEMENTATION.md.

```markdown
## [3.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.2.0)

Released on YYYY-MM-DD.

### Added
- Added Swift 6 language mode (`swiftLanguageModes: [.v6]`) to `Package.swift`.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `CDMarkdownTaskList` element for parsing GFM task list items (`- [ ]` / `- [x]`).
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `CDMarkdownHorizontalRule` element for parsing horizontal rules (`---`, `***`, `___`).
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added inline markdown parsing inside GFM table cells (bold, italic, links, inline code).
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `disabledElementTypes`, `disable(_:)`, and `enable(_:)` to `CDMarkdownParser` for opting out of individual default elements.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `insertCustomElement(_:before:)` and `insertCustomElement(_:after:)` to `CDMarkdownParser` for precise pipeline positioning.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added accessibility attribute keys (`cdMarkdownHeadingLevel`, `cdMarkdownIsCode`, `cdMarkdownIsBlockquote`) and `accessibilityAttributedString(from:)` helper on `CDMarkdownParser`.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `CDMarkdownNSLayoutManager`, `CDMarkdownNSTextView`, and `CDMarkdownNSLabel` — AppKit UI components for macOS.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `CDMarkdownText` and `CDMarkdownView` — SwiftUI wrappers for iOS, tvOS, macOS, watchOS, and visionOS.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
- Added `markdownParser` SwiftUI environment key and `.markdownParser(_:)` view modifier.
  - Added by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).

### Updated
- Deprecated synchronous `parse(_:)` overloads in favour of the async overloads.
  - Updated by [Christopher de Haan](https://github.com/chrisdhaan) in Pull Request [#NN](link).
```

Fill in the PR number and release date before merging.

---

**7.4 — Regenerate the DocC static site**

Run the following from the repository root to regenerate `docs/` with the updated version:

```bash
swift package --disable-sandbox generate-documentation \
  --target CDMarkdownKit \
  --output-path docs \
  --transform-for-static-hosting \
  --hosting-base-path CDMarkdownKit
```

Stage the updated `docs/` directory alongside the version bump and CHANGELOG update.

---

**7.5 — Run all checks**

Before merging, verify the following all pass cleanly:

1. `swift build`
2. `swift test`
3. `bundle exec pod lib lint --allow-warnings`
4. `swiftlint lint --strict`
5. `swiftformat Source Tests --lint`
6. All CI jobs are green (iOS, macOS, tvOS, watchOS, visionOS, Catalyst, CocoaPods, SPM, SwiftLint, SwiftFormat, CodeQL, DocC).

Fix any failures before proceeding.

---

**7.6 — Merge the PR to `master`**

On GitHub, merge the pull request using whichever merge strategy is consistent with the project's existing history on `master`. After merging, pull `master` locally:

```bash
git checkout master
git pull origin master
```

---

**7.7 — Tag and create the GitHub Release**

```bash
git tag 3.2.0
git push origin 3.2.0
```

On GitHub, go to **Releases → Create a new release**, select the `3.2.0` tag, set the title to `3.2.0`, and paste the CHANGELOG entry from step 7.3 as the release notes.

---

**7.8 — Push to CocoaPods trunk**

```bash
bundle exec pod trunk push CDMarkdownKit.podspec --allow-warnings
```

Confirm `pod trunk me` shows the correct account before running the push. Once the push succeeds, the new version will be available via `pod 'CDMarkdownKit', '~> 3.2'`.
