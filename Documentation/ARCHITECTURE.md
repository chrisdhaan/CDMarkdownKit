# CDMarkdownKit — Architecture Reference

## Parsing Pipeline

`CDMarkdownParser` is `@MainActor`. `parse(_:)` is `async` and runs every time you call it. It does four things in order:

```
Input: String or NSAttributedString
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Pre-processing                                             │
│  • squashNewlines: collapse \n\n+ → \n except in fences     │
│  • replace &nbsp; → space                                   │
│  • dedent leading whitespace (strip only the common margin) │
│  • apply base font / color / background / paragraphStyle   │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1 — REFERENCE DEFINITION EXTRACTION                 │
│                                                             │
│  CDMarkdownLinkReference                                    │
│    Strips [ref]: url lines from the string and populates    │
│    CDMarkdownLinkReference.references with the mappings,   │
│    so Phase 2 link reference parsing can resolve them.      │
│    Runs against the raw string, before escaping, so         │
│    literal title punctuation (e.g. \" inside a quoted        │
│    title) hasn't been UTF16-hex-encoded yet.                │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1.5 — ESCAPING                                       │
│                                                             │
│  CDMarkdownCodeEscaping                                     │
│    Converts content inside backtick spans to UTF16-hex      │
│    so no inner markdown can match them.                     │
│    e.g.  `**bold**`  →  `002a002a626f6c64002a002a`         │
│                                                             │
│  CDMarkdownEscaping                                         │
│    Converts \-escaped single characters to UTF16-hex.       │
│    e.g.  \*  →  \002a                                       │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2 — ELEMENT PARSING  (order is fixed)               │
│                                                             │
│  CDMarkdownTable          pipe-delimited rows               │
│  CDMarkdownHorizontalRule --- / *** / ___ dividers          │
│  CDMarkdownHeader         # H1  through  ###### H6         │
│  CDMarkdownTaskList       - [x] / - [ ] items              │
│  CDMarkdownList           * / - / + items (nested)         │
│  CDMarkdownOrderedList    1. / 2. numbered items            │
│  CDMarkdownQuote          > blockquotes (nested)           │
│  CDMarkdownLink           [text](url)                      │
│  CDMarkdownAutomaticLink  bare URLs via NSDataDetector      │
│  CDMarkdownLinkReference  [text][ref] resolved references   │
│  CDMarkdownImage          ![alt](url)                      │
│  CDMarkdownBold           **text** or __text__             │
│  CDMarkdownItalic         *text* or _text_                 │
│  CDMarkdownStrikethrough  ~~text~~                         │
│  [customElements]         caller-supplied elements         │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 3 — UNESCAPING                                       │
│                                                             │
│  CDMarkdownCode                                             │
│    Handles `inline code`: decodes UTF16-hex content,        │
│    applies Menlo font + red theme, strips embedded \n       │
│                                                             │
│  CDMarkdownSyntax                                           │
│    Handles ```fenced blocks```: decodes UTF16-hex content,  │
│    applies Menlo font + gray theme, manages background-     │
│    color wrapping at line boundaries                        │
│                                                             │
│  CDMarkdownUnescaping                                       │
│    Converts any remaining \HHHH sequences back to chars     │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Async Image Resolution                                     │
│                                                             │
│  resolveImages(in:)                                         │
│    Finds NSTextAttachment placeholders inserted by          │
│    CDMarkdownImage.match(), downloads each remote image     │
│    via URLSession (back-deployed async API), scales to      │
│    CDMarkdownParser.image.size, and updates the attachment  │
└─────────────────────────────────────────────────────────────┘
│
▼
Output: NSAttributedString
```

---

## Protocol Hierarchy

```
CDMarkdownElement                          Foundation
│  var regex: String                       NSRegularExpression
│  func regularExpression() throws         (default: plain regex)
│  func parse(_ NSMutableAttributedString) (default: firstMatch loop)
│  func match(_ NSTextCheckingResult, _)   (must override)
│
├── CDMarkdownCommonElement : CDMarkdownElement, CDMarkdownStyle
│   │  func addAttributes(_:range:)        (default: applies self.attributes)
│   │  func match(_:attributedString:)     deletes trailing+leading delimiters,
│   │                                      then calls addAttributes on inner text
│   │
│   ├── CDMarkdownBold           regex group [4]: ()(**|__)(content)(\2)
│   ├── CDMarkdownItalic         regex group [4]: ()(*|_)(content)(\2)
│   ├── CDMarkdownCode           overrides addAttributes: unescape + strip \n
│   ├── CDMarkdownSyntax         overrides addAttributes: unescape + bg wrapping
│   └── CDMarkdownStrikethrough  sets strikethroughColor/strikethroughStyle (default attributes impl covers the rest)
│
├── CDMarkdownLevelElement : CDMarkdownElement, CDMarkdownStyle
│   │  var maxLevel: Int
│   │  func regularExpression()            uses .anchorsMatchLines
│   │  func formatText(_:range:level:)     (must override) replaces marker text
│   │  func addFullAttributes(_:range:level:)  (optional) full-line attrs
│   │  func addAttributes(_:range:level:)  (default: attributesForLevel)
│   │  func attributesForLevel(_ Int)      (default: self.attributes)
│   │  func match(_:attributedString:)     extracts level from capture group 1 length
│   │
│   ├── CDMarkdownHeader         formatText removes #s; attributesForLevel scales font
│   ├── CDMarkdownList           formatText replaces marker with "• "; addFullAttributes
│   │                            sets headIndent for paragraph alignment
│   ├── CDMarkdownOrderedList    formatText replaces "N." with "N."; tracks numbering
│   ├── CDMarkdownTaskList       formatText replaces "- [x]"/"- [ ]" with ✓/☐
│   └── CDMarkdownQuote          formatText replaces > with indicator string
│
├── CDMarkdownLinkElement : CDMarkdownElement, CDMarkdownStyle
│   │  func formatText(_:range:link:)      (must override) attaches URL attribute
│   │  func addAttributes(_:range:link:)   (must override) adds visual attrs
│   │
│   ├── CDMarkdownLink           formatText: URL percent-encoding + .link attr
│   ├── CDMarkdownAutomaticLink  extends Link; regularExpression returns NSDataDetector
│   ├── CDMarkdownLinkReference  resolves [text][ref] against CDMarkdownLinkReference.references
│   └── CDMarkdownImage          match: inserts placeholder NSTextAttachment; async
│                                resolution happens in CDMarkdownParser.resolveImages(in:)
│
└── Direct CDMarkdownElement implementations (no shared sub-protocol)
    ├── CDMarkdownTable          pipe-delimited GFM tables; writes per-cell paragraph attrs
    ├── CDMarkdownHorizontalRule matches ---, ***, ___ and replaces with styled rule character
    ├── CDMarkdownCodeEscaping   UTF16-hex-encodes backtick span contents (Phase 1.5)
    ├── CDMarkdownEscaping       UTF16-hex-encodes backslash-escaped chars (Phase 1.5)
    └── CDMarkdownUnescaping     reverses all remaining \HHHH sequences (Phase 3)
```

---

## Styling Protocol

```swift
protocol CDMarkdownStyle {
    var font: CDFont? { get }
    var color: CDColor? { get }
    var backgroundColor: CDColor? { get }
    var paragraphStyle: NSParagraphStyle? { get }
    var underlineColor: CDColor? { get }
    var underlineStyle: NSUnderlineStyle? { get }
    var strikethroughColor: CDColor? { get }
    var strikethroughStyle: NSUnderlineStyle? { get }
    var attributes: [CDAttributedStringKey: AnyObject] { get }  // default impl
}
```

Every element that conforms to `CDMarkdownStyle` gets `attributes` for free: it assembles a dictionary from the non-nil properties, including `strikethroughColor`/`strikethroughStyle` for elements that set them (only `CDMarkdownStrikethrough` does by default). No element currently overrides `attributes` or `addAttributes` to inject extra attributes beyond what the default `attributes` dictionary provides.

---

## UI Components

### CDMarkdownLayoutManager (iOS/tvOS)

Subclass of `NSLayoutManager`. Overrides `fillBackgroundRectArray(_:count:forCharacterRange:color:)` to draw rounded rectangles around background-colored runs instead of sharp rectangles.

Corner radius is set to 3pt when:
- `roundCodeCorners == true` AND the attributed string has a `.cdMarkdownRoundedBackground` attribute matching a code span
- `roundSyntaxCorners == true` AND the attribute matches a syntax span
- `roundAllCorners == true` (regardless of color)

Rounding decisions are driven by the `.cdMarkdownRoundedBackground` custom attribute written during parsing — not by color comparison — so customized colors are handled correctly.

### CDMarkdownTextView (iOS/tvOS/visionOS)

`@MainActor UITextView` subclass. `configure()` picks a rendering path based on OS availability:
- **iOS/tvOS 16+ (TextKit 2)**: `configureTK2()` creates a `CDMarkdownTextLayoutDelegate` (an `NSTextLayoutManagerDelegate`, defined in `CDMarkdownTextLayoutManager.swift`) and assigns it to the view's stock `textLayoutManager`. The delegate supplies `CDMarkdownTextLayoutFragment` instances, which draw the rounded-corner backgrounds.
- **iOS/tvOS 15 (TextKit 1 fallback)**: `configureTK1()` creates a `CDMarkdownLayoutManager`, wires it into the text container, and keeps a `customTextStorage` in sync with the layout manager on each `attributedText` update.

`makeTextView(frame:)` is the preferred factory for programmatic construction — it calls `configure()`, which auto-selects TextKit 2 on iOS/tvOS 16+.

### CDMarkdownLabel (iOS/tvOS/visionOS)

`@MainActor UILabel` subclass that maintains its own text rendering stack, also TextKit-version-branched via `configure()`:
- **iOS/tvOS 16+ (TextKit 2)**: `configureTK2()` builds an `NSTextContentStorage` + stock `NSTextLayoutManager`, assigns a `CDMarkdownTextLayoutDelegate`, and drives layout/drawing/hit-testing through that stack (`drawTextTK2`, `urlRangeTK2`, etc.).
- **iOS/tvOS 15 (TextKit 1 fallback)**: `configureTK1()` builds `NSTextStorage + CDMarkdownLayoutManager + NSTextContainer` directly, with `maximumNumberOfLines = 0` (unlimited) regardless of `UILabel.numberOfLines`.

Supports tapping links on both paths:
- `touchesBegan/Moved/Ended` track which URL was tapped
- `touchesEnded` opens a `UIAlertController` action sheet with Open / Add to Reading List / Copy / Share options
- `CDMarkdownLabelDelegate.didSelect(_:URL)` is called on "Open"
- On the TextKit 1 path, implements `NSLayoutManagerDelegate` to prevent line breaks mid-URL

### CDMarkdownNSTextView (macOS)

`NSTextView` subclass with rounded-corner support via `CDMarkdownNSLayoutManager`. Configured as read-only, non-editable by default. Links in the attributed string are opened by `NSWorkspace` on click unless a custom `NSTextViewDelegate` intercepts them. Use `setAttributedString(_:)` to display parsed markdown.

### CDMarkdownNSLabel (macOS)

Lightweight read-only `NSView` for simple markdown display without link interaction. Backs its text with `NSAttributedString` drawn directly in `drawRect(_:)`. Set `attributedText` to update the display.

### CDMarkdownNSLayoutManager (macOS)

`NSLayoutManager` subclass parallel to `CDMarkdownLayoutManager` for macOS. Provides the same rounded-corner background rendering using the `.cdMarkdownRoundedBackground` attribute.

---

## SwiftUI Components

### CDMarkdownText

Lightweight SwiftUI view backed by SwiftUI's native `Text` view with `AttributedString`. Does not support rounded-corner code backgrounds, but works on all SwiftUI platforms including watchOS.

### CDMarkdownView

Full-fidelity SwiftUI view backed by `CDMarkdownTextView` (iOS/tvOS/visionOS) or `CDMarkdownNSTextView` (macOS). Supports rounded-corner backgrounds, link tap handling, and async image loading.

### CDMarkdownEnvironmentKey

Provides `.markdownParser(_:)` and `.markdownTheme(_:)` SwiftUI environment modifiers. Any `CDMarkdownText` or `CDMarkdownView` in the subtree picks up the environment parser or builds one from the theme automatically.

---

## CDMarkdownTheme

`CDMarkdownTheme` is a value type that bundles the visual styling for all elements. Pass it to `CDMarkdownParser(theme:)` to style the entire parser at once without setting properties element-by-element.

Built-in themes: `CDMarkdownTheme.default` (mirrors parser defaults) and `CDMarkdownTheme.systemDark` (dark-mode friendly using system colors).

---

## Cross-Platform Type Map

| Abstract type | iOS / tvOS / watchOS | macOS |
|--------------|---------------------|-------|
| `CDFont` | `UIFont` | `NSFont` |
| `CDColor` | `UIColor` | `NSColor` |
| `CDImage` | `UIImage` | `NSImage` |
| `CDAttributedStringKey` | `NSAttributedString.Key` | same |

Font manipulation (`bold()`, `italic()`, `withSize()`) diverges by platform:
- **iOS/tvOS/watchOS**: uses `UIFontDescriptor.SymbolicTraits`
- **macOS**: uses `NSFontManager`

---

## Escaping / Unescaping Mechanism

Code spans must not have their contents parsed as markdown. The mechanism:

1. **CDMarkdownCodeEscaping** — regex: `` (?<!\\)(?:\\\\)*+(`+)(.*?[^`].*?)(\1)(?!`) ``  
   Converts each UTF16 code unit of the captured inner content to a 4-hex-digit string (e.g., `H` → `0048`). The backtick delimiters are left in place.

2. **CDMarkdownEscaping** — regex: `\\.`  
   Converts the single character following a backslash the same way. The leading backslash is left in place.

3. Element parsing runs (none of the hex sequences match any element regex).

4. **CDMarkdownCode / CDMarkdownSyntax** (during Phase 3) — their `addAttributes` implementations call `String.unescapeUTF16()` to reverse the hex encoding before applying text attributes.

5. **CDMarkdownUnescaping** — regex: `\\[0-9a-z]{4}`  
   Catches any remaining `\HHHH` sequences (from `CDMarkdownEscaping`) and converts them back.

---

## Regex Capture Group Conventions

**CommonElement** (groups 1–4):
```
group 0: full match
group 1: empty leading capture (position anchor)
group 2: opening delimiter
group 3: content
group 4: closing delimiter (backreference to group 2)
```
`match()` deletes group 4, applies attributes to group 3, then deletes group 2.

**LevelElement** (groups 0–2):
```
group 0: full match (including leading whitespace and trailing newline)
group 1: the level markers (e.g., "##" — its .length is the level number)
group 2: content text
```

**LinkElement**: custom `match()` implementations; use `NSString.range(of:options:range:)` to find the `(` boundary dynamically.

---

## Dependency Graph (Zero External Dependencies)

```
CDMarkdownKit
└── Foundation            (all platforms)
└── UIKit                 (iOS, tvOS, watchOS)
└── Cocoa                 (macOS)
    └── SafariServices    (iOS only, for SSReadingList in CDMarkdownLabel)
```
