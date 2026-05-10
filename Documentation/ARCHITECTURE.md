# CDMarkdownKit — Architecture Reference

## Parsing Pipeline

`CDMarkdownParser` is `@MainActor`. `parse(_:)` is `async` and runs every time you call it. It does four things in order:

```
Input: String or NSAttributedString
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Pre-processing                                             │
│  • squashNewlines: collapse \n\n+ → \n                     │
│  • replace &nbsp; → space                                   │
│  • strip leading whitespace on each line                    │
│  • apply base font / color / background / paragraphStyle   │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1 — ESCAPING                                         │
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
│  CDMarkdownHeader         # H1  through  ###### H6         │
│  CDMarkdownList           * / - / + items (nested)         │
│  CDMarkdownQuote          > blockquotes (nested)           │
│  CDMarkdownLink           [text](url)                      │
│  CDMarkdownAutomaticLink  bare URLs via NSDataDetector      │
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
│   └── CDMarkdownStrikethrough  overrides addAttributes: adds strikethrough attrs
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
│   ├── CDMarkdownHeader   formatText removes #s; attributesForLevel scales font
│   ├── CDMarkdownList     formatText replaces marker with "• "; addFullAttributes
│   │                      sets headIndent for paragraph alignment
│   └── CDMarkdownQuote    formatText replaces > with indicator string
│
└── CDMarkdownLinkElement : CDMarkdownElement, CDMarkdownStyle
    │  func formatText(_:range:link:)      (must override) attaches URL attribute
    │  func addAttributes(_:range:link:)   (must override) adds visual attrs
    │
    ├── CDMarkdownLink           formatText: URL percent-encoding + .link attr
    ├── CDMarkdownAutomaticLink  extends Link; regularExpression returns NSDataDetector
    └── CDMarkdownImage          match: inserts placeholder NSTextAttachment; async
                                 resolution happens in CDMarkdownParser.resolveImages(in:)
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
    var attributes: [CDAttributedStringKey: AnyObject] { get }  // default impl
}
```

Every element that conforms to `CDMarkdownStyle` gets `attributes` for free: it assembles a dictionary from the non-nil properties. Elements can override `attributes` (none currently do) or override `addAttributes` to inject extra attributes (e.g., `CDMarkdownStrikethrough` adds strikethrough color/style on top of the base attributes).

---

## UI Components

### CDMarkdownLayoutManager (iOS/tvOS)

Subclass of `NSLayoutManager`. Overrides `fillBackgroundRectArray(_:count:forCharacterRange:color:)` to draw rounded rectangles around background-colored runs instead of sharp rectangles.

Corner radius is set to 3pt when:
- `roundCodeCorners == true` AND color matches `CDColor.codeBackgroundRed()`
- `roundSyntaxCorners == true` AND color matches `CDColor.syntaxBackgroundGray()`  
- `roundAllCorners == true` (regardless of color)

**Known fragility**: the color comparison is by RGBA value; it won't round custom colors.

### CDMarkdownTextView (iOS/tvOS)

`@MainActor UITextView` subclass. When initialized programmatically (preferred), caller provides a pre-wired `CDMarkdownLayoutManager`. When initialized from a storyboard, `configure()` creates its own layout manager, calls `addTextContainer(self.textContainer)` to take over rendering, and forces `isScrollEnabled = true`, `isSelectable = false`, `isEditable = false`. The `attributedText` setter keeps a separate `customTextStorage` (a copy of the attributed text) wired to the layout manager so it has content to draw from.

**TextKit 1 note**: accessing `self.textContainer` in `configure()` opts UITextView into TextKit 1 compatibility mode. The one-time console warning this produces is expected and unavoidable until `CDMarkdownLayoutManager` is migrated to `NSTextLayoutManager`.

### CDMarkdownLabel (iOS/tvOS)

`@MainActor UILabel` subclass that maintains its own text rendering stack (`NSTextStorage + NSLayoutManager + NSTextContainer`). The text container is initialized with `maximumNumberOfLines = 0` (unlimited) regardless of `UILabel.numberOfLines`. Supports tapping links:
- `touchesBegan/Moved/Ended` track which URL was tapped
- `touchesEnded` opens a `UIAlertController` action sheet with Open / Add to Reading List / Copy / Share options
- `CDMarkdownLabelDelegate.didSelect(_:URL)` is called on "Open"
- Implements `NSLayoutManagerDelegate` to prevent line breaks mid-URL

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
