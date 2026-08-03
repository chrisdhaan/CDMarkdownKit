# CDMarkdownKit Usage Guide

A pure-Swift, zero-dependency framework for parsing Markdown text into styled `NSAttributedString`.

## Basic Setup

CDMarkdownKit is distributed via Swift Package Manager and CocoaPods.

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", from: "4.0.0")
```

Or in Xcode: **File → Add Packages** and enter the repository URL.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CDMarkdownKit', '~> 4.0'
```

Run `pod install`.

---

## CDMarkdownParser

The main entry point for parsing Markdown into styled `NSAttributedString`.

### Creating a Parser

```swift
import CDMarkdownKit

// Basic parser with defaults
let parser = CDMarkdownParser()

// Parser with custom styling
let parser = CDMarkdownParser(
    font: UIFont.systemFont(ofSize: 16),
    boldFont: UIFont.boldSystemFont(ofSize: 16),
    italicFont: UIFont.italicSystemFont(ofSize: 16),
    fontColor: UIColor.black,
    backgroundColor: UIColor.white
)
```

### Parsing Markdown

```swift
// Synchronous parsing
let markdown = "# Hello **World**\n\nThis is *italic* text."
let attributedString = parser.parse(markdown)

// Asynchronous parsing (v3.0+, for image loading)
let attributedString = await parser.parse(markdown)
```

### Configuration Options

```swift
// Enable/disable automatic URL detection
parser.automaticLinkDetectionEnabled = true  // default: true

// Collapse multiple newlines
parser.squashNewlines = true  // default: true

// Add custom Markdown elements
let customElement = MyCustomElement()
parser.addCustomElement(customElement)
parser.removeCustomElement(customElement)
```

### Customizing the Element Pipeline

#### Disabling default elements

Exclude specific built-in elements from parsing without subclassing:

```swift
let parser = CDMarkdownParser()
parser.disable(CDMarkdownHeader.self)        // raw # syntax passes through
parser.disable(CDMarkdownAutomaticLink.self) // no automatic URL detection
```

Re-enable at any time:

```swift
parser.enable(CDMarkdownHeader.self)
```

#### Inserting custom elements at specific positions

By default, custom elements run after all built-in elements. Use `insertCustomElement(_:before:)` or `insertCustomElement(_:after:)` to position them precisely:

```swift
let mention = CDMarkdownMention()
parser.insertCustomElement(mention, before: CDMarkdownBold.self)
```

#### Async vs. synchronous parsing

Prefer the async overload for all new code:

```swift
let attributed = await parser.parse("Hello **world**")
```

The synchronous `parse(_:)` overloads are deprecated and will be removed in a future major version. They remain available for backward compatibility.

### Customizing Element Styling

Each element has configurable styling:

```swift
parser.bold.color = UIColor.red
parser.italic.font = UIFont.italicSystemFont(ofSize: 18)
parser.code.backgroundColor = UIColor.lightGray
parser.link.color = UIColor.blue
parser.header.fontIncrease = 4
```

### Theming

Use `CDMarkdownTheme` to style an entire parser in one call instead of setting properties
on each element individually:

```swift
var theme = CDMarkdownTheme.default
theme.code = CDMarkdownTheme.InlineTheme(
    font: CDFont(name: "JetBrainsMono-Regular", size: 13)!,
    color: CDColor.orange,
    backgroundColor: CDColor.darkGray
)
theme.link = CDMarkdownTheme.LinkTheme(color: CDColor.systemBlue)

let parser = CDMarkdownParser(theme: theme)
```

Built-in themes: `CDMarkdownTheme.default`, `CDMarkdownTheme.systemDark`.

In SwiftUI, apply a theme to a subtree with `.markdownTheme(_:)`:

```swift
ContentView()
    .markdownTheme(.systemDark)
```

Individual element properties can still be overridden on the parser after `init(theme:)`.
Per-element overrides always win over theme values.

### Preserving Leading Whitespace

By default, CDMarkdownKit dedents leading whitespace: it only strips whitespace common to every line, preserving relative indentation between lines (similar to Python's `textwrap.dedent`). This is suitable for most Markdown text, but if you need to preserve indentation unconditionally — such as in code blocks or other contexts where even a lone indented line should keep its whitespace — enable the `preserveLeadingWhitespace` option:

```swift
let parser = CDMarkdownParser()
parser.preserveLeadingWhitespace = true
let attributed = parser.parse("""
    ```
       function sayHello() {
          console.log("Hello, World!");
       }
    ```
    """)
```

With `preserveLeadingWhitespace = true`, the indentation inside both inline code (`` `...` ``) and fenced code blocks (` ``` `) is preserved as-is. This is useful for:
- Code examples with semantic indentation
- ASCII art or diagrams
- Poetry or formatted prose
- Any content where whitespace spacing is meaningful
- Indentation-based nested unordered lists (e.g. `- item` / `  - subitem`)

**Note**: This setting affects code elements (as above) and unordered list nesting. `CDMarkdownList` derives each item's nesting level from its leading whitespace. With the default `preserveLeadingWhitespace = false`, the parser dedents rather than stripping outright, so indentation-based nested unordered lists already work across multi-line input without opting in — a margin only gets stripped if it's common to every line in the document. A single orphaned indented line is the exception: its entire indent *is* the margin, so it gets fully stripped by default. Enable `preserveLeadingWhitespace = true` when you need indentation preserved unconditionally, including for a lone indented line or for code blocks. Repeated marker characters (`** item`, `*** item`) remain an alternative for list nesting that works regardless of indentation or whitespace settings.

---

## Supported Syntax

CDMarkdownKit supports the following Markdown syntax:

| Syntax | Example | Output |
|--------|---------|--------|
| Bold | `**bold**` or `__bold__` | **bold** text |
| Italic | `*italic*` or `_italic_` | *italic* text |
| Strikethrough | `~~crossed~~` | ~~crossed~~ text |
| Headers | `# H1` through `###### H6` | Scaled font sizes |
| Unordered Lists | `* item` or `- item` or `+ item` | Bulleted items |
| Blockquotes | `> quote` | Indented text |
| Inline Code | `` `code` `` | Monospace text |
| Fenced Code | ` ```code``` ` | Multi-line code block |
| Links | `[text](url)` | Clickable URLs |
| Automatic Links | `https://example.com` | Bare URLs detected |
| Images | `![alt](url)` | Rendered images |
| Ordered Lists | `1. item` | Numbered items |
| Task Lists | `- [x] done` / `- [ ] todo` | Checked items |
| Horizontal Rules | `---` or `***` or `___` | Divider line |
| Tables | Pipe-delimited rows | Aligned columns |
| Reference Links | `[text][ref]` + `[ref]: url` | Named URL references |

### Platform Notes

| Feature | iOS | macOS | tvOS | watchOS | visionOS |
|---------|-----|-------|------|---------|----------|
| Bold / Italic / Strikethrough | ✓ | ✓ | ✓ | ✓ | ✓ |
| Headers | ✓ | ✓ | ✓ | ✓ | ✓ |
| Unordered Lists | ✓ | ✓ | ✓ | ✓ | ✓ |
| Ordered Lists | ✓ | ✓ | ✓ | ✓ | ✓ |
| Blockquotes | ✓ | ✓ | ✓ | ✓ | ✓ |
| Inline Code / Fenced Blocks | ✓ | ✓ | ✓ | ✓ | ✓ |
| Task Lists | ✓ | ✓ | ✓ | ✓ | ✓ |
| Horizontal Rules | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tables | ✓ | ✓ | ✓ | ✓ | ✓ |
| Reference Links | ✓ | ✓ | ✓ | ✓ | ✓ |
| Links (tappable) | ✓ | ✓ | ✓ | — | ✓ |
| Automatic Links | ✓ | ✓ | ✓ | — | ✓ |
| Images | ✓ | ✓ | ✓ | — | ✓ |

> **watchOS**: Only `WKInterfaceLabel.setAttributedText(_:)` is supported. Tappable links, images, and `CDMarkdownLabel`/`CDMarkdownTextView` UI components are not available on watchOS. All text styling (bold, italic, headers, code, tables, etc.) works because it is applied as `NSAttributedString` attributes, which `WKInterfaceLabel` renders correctly.

### Tables

CDMarkdownKit supports GitHub Flavored Markdown tables with optional leading/trailing pipes:

```
| Column 1 | Column 2 | Column 3 |
| :------- | :------: | -------: |
| left     | center   | right    |
```

Column alignment is controlled by the colon position in the separator row:
- `:---` (or `---`) — Left-aligned
- `:---:` — Center-aligned
- `---:` — Right-aligned

Cell content supports inline formatting — bold, italic, strikethrough, code spans, and links inside cells are all rendered.

### Reference-Style Links

CDMarkdownKit supports Markdown reference-style links. Reference definitions are stripped
from the output and their URLs are resolved when the link is rendered:

```
See the [CDMarkdownKit repo][cdmk] for more details.

[cdmk]: https://github.com/chrisdhaan/CDMarkdownKit
```

The link text (`CDMarkdownKit repo`) is written to the attributed string as a tappable
`.link` attribute pointing to the resolved URL. The reference definition line is removed
from the output entirely.

CDMarkdownKit also writes the original link title (the first capture from the reference
definition) to the `.cdMarkdownLinkTitle` custom attribute. Use this to display tooltips
or accessible descriptions:

```swift
let attributed = await parser.parse(markdown)
attributed.enumerateAttribute(.cdMarkdownLinkTitle,
                               in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
    guard let title = value as? String else { return }
    // e.g., attach as accessibility label for the link range
}
```

### Fenced Code Blocks

CDMarkdownKit supports triple-backtick fenced code blocks with optional language hints.

#### Language hint attribute

When a fenced code block includes a language hint (e.g. ` ```swift `), CDMarkdownKit writes
it to the attributed string as the `.cdMarkdownCodeLanguage` attribute. Use this to implement
syntax highlighting:

```swift
let attributed = await parser.parse(markdown)
attributed.enumerateAttribute(.cdMarkdownCodeLanguage,
                               in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
    guard let language = value as? String else { return }
    // Apply your own syntax highlighting to `range` for `language`
}
```

The attribute is a `String` whose value is the exact text after the opening fence — `"swift"`,
`"python"`, `"js"`, etc. It is absent when no hint is given.

---

## CDMarkdownLabel

A `UILabel` subclass that renders styled Markdown with clickable links.

### Basic Usage

```swift
import UIKit
import CDMarkdownKit

class MyViewController: UIViewController {
    @IBOutlet weak var label: CDMarkdownLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parser = CDMarkdownParser()
        let markdown = "Check out [CDMarkdownKit](https://github.com/chrisdhaan/CDMarkdownKit)"
        label.attributedText = parser.parse(markdown)
    }
}
```

### Handling Link Taps

```swift
class MyViewController: UIViewController, CDMarkdownLabelDelegate {
    @IBOutlet weak var label: CDMarkdownLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.delegate = self
    }
    
    func didSelect(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}
```

### Customizing Appearance

```swift
label.roundAllCorners = true  // Round corners on code/syntax backgrounds
label.numberOfLines = 0       // Allow unlimited lines
label.lineBreakMode = .byWordWrapping
```

---

## CDMarkdownTextView

A `UITextView` subclass for rendering styled Markdown with custom layout.

### Basic Usage

```swift
import UIKit
import CDMarkdownKit

let textView = CDMarkdownTextView()
let parser = CDMarkdownParser()
let markdown = """
# Welcome

This is a **rich** markdown document.
"""
textView.attributedText = parser.parse(markdown)
```

### Handling Link Interactions

Set `isSelectable = true` and implement the delegate:

```swift
textView.isSelectable = true
textView.delegate = self

// MARK: - UITextViewDelegate

func textView(_ textView: UITextView,
              shouldInteractWith url: URL,
              in characterRange: NSRange,
              interaction: UITextItemInteraction) -> Bool {
    if url.scheme == "http" || url.scheme == "https" {
        UIApplication.shared.open(url)
        return false  // Prevent default behavior
    }
    return true
}
```

### Customizing Appearance

```swift
textView.roundAllCorners = true
textView.isScrollEnabled = true
textView.isEditable = false
```

---

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

Set a parser or theme once for a whole view hierarchy:

```swift
ContentView()
    .markdownParser(myParser)

// Or share just a theme (a parser is created from it automatically)
ContentView()
    .markdownTheme(.systemDark)
```

Any `CDMarkdownText` or `CDMarkdownView` in the subtree will use `myParser` (or the
derived parser) unless overridden with an explicit `parser:` argument.

---

## Custom Elements

`CDMarkdownParser` accepts an array of `customElements`. Each element must conform to `CDMarkdownElement` and optionally `CDMarkdownStyle`. Custom elements run after all built-in elements in Phase 2 of the parsing pipeline.

### Example: @mention with tap handling

**Step 1 — Define the element:**

```swift
import CDMarkdownKit
import UIKit

final class CDMarkdownMention: CDMarkdownElement, CDMarkdownStyle {

    // Matches @username — word characters only, no spaces
    var regex: String { "(?<![\\w])@(\\w+)" }

    // Visual style
    var font: CDFont?
    var color: CDColor? = .systemBlue
    var backgroundColor: CDColor?
    var paragraphStyle: NSParagraphStyle?
    var underlineColor: CDColor?
    var underlineStyle: NSUnderlineStyle?

    func match(_ match: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        let range = match.range   // full @username range
        var attrs = attributes
        // Store the username (without @) as a custom link URL so taps are routable
        let username = (attributedString.string as NSString).substring(with: match.range(at: 1))
        if let url = URL(string: "mention://\(username)") {
            attrs[.link] = url
        }
        attributedString.addAttributes(attrs, range: range)
    }
}
```

**Step 2 — Register it with the parser:**

```swift
let parser = CDMarkdownParser(font: UIFont.systemFont(ofSize: 16))
parser.customElements = [CDMarkdownMention()]
let attributed = parser.parse("Hello @alice, check this out!")
textView.attributedText = attributed
```

**Step 3 — Handle taps in `CDMarkdownLabel`:**

```swift
extension MyViewController: CDMarkdownLabelDelegate {
    func didSelect(_ url: URL) {
        if url.scheme == "mention", let username = url.host {
            // Navigate to the user's profile
            showProfile(for: username)
        }
    }
}

// In viewDidLoad:
markdownLabel.delegate = self
```

**Step 4 — Handle taps in `CDMarkdownTextView` / `UITextView`:**

```swift
extension MyViewController: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        if url.scheme == "mention", let username = url.host {
            showProfile(for: username)
            return false   // prevent default URL-open behavior
        }
        return true
    }
}
```

> **Tip:** Any `URL` stored in the `.link` attribute will be delivered to both `CDMarkdownLabelDelegate.didSelect(_:)` and the `UITextViewDelegate` method above. Use a custom URL scheme (e.g., `mention://`, `hashtag://`) to distinguish your custom elements from ordinary http/https links.

---

## Styling

All Markdown elements conform to the `CDMarkdownStyle` protocol, which exposes:

- `font` — The typeface and size
- `color` — Text foreground color
- `backgroundColor` — Background color
- `paragraphStyle` — Line spacing, alignment, indentation
- `underlineColor` — Color of underlines
- `underlineStyle` — Style of underlines (.single, .double, etc.)
- `strikethroughColor` — Color of strikethrough lines
- `strikethroughStyle` — Style of strikethrough lines

### Styling Individual Elements

```swift
let parser = CDMarkdownParser()

// Style headers
let headerStyle = NSMutableParagraphStyle()
headerStyle.paragraphSpacing = 12
parser.header.color = UIColor.darkBlue
parser.header.paragraphStyle = headerStyle

// Style code blocks
parser.code.backgroundColor = UIColor.lightGray
parser.code.color = UIColor.darkRed

// Style links
parser.link.color = UIColor.systemBlue
parser.link.underlineStyle = .single
```

### Using Custom Fonts

```swift
let monoFont = UIFont(name: "Menlo", size: 12) ?? UIFont.systemFont(ofSize: 12)
let parser = CDMarkdownParser(font: monoFont)

// Or update individual elements
parser.code.font = monoFont
parser.syntax.font = monoFont
```

---

## Async Parsing (v3.0+)

For documents with remote images, use the async `parse(_:)` overload to load images without blocking the main thread.

### Basic Usage

```swift
// Synchronous (blocks on remote images)
let attributedString = parser.parse(markdown)

// Asynchronous (loads images in background)
let attributedString = await parser.parse(markdown)
```

### With Image Display

```swift
Task {
    let attributedString = await parser.parse(markdownWithImages)
    DispatchQueue.main.async {
        self.textView.attributedText = attributedString
    }
}
```

### How It Works

- The async variant first parses without loading images, inserting placeholder attributes
- Images are then loaded concurrently using `URLSession.shared.data(from:)`
- Loaded images replace the placeholders in the attributed string
- The parser respects custom image sizing from `CDMarkdownParser(imageSize:)`

> **Note:** The synchronous `parse(_:)` blocks on remote images. Use the async variant when parsing documents with external image URLs to prevent UI freezing.

---

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

**Note**: `accessibilityAttributedString(from:)` is available on iOS and visionOS only. It is not available on tvOS, where VoiceOver navigation works differently.

VoiceOver will announce headings with their level ("Heading level 1: Introduction"),
helping users navigate document structure with the rotor.
