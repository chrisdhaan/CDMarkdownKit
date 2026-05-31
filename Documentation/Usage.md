# CDMarkdownKit Usage Guide

A pure-Swift, zero-dependency framework for parsing Markdown text into styled `NSAttributedString`.

## Basic Setup

CDMarkdownKit is distributed via Swift Package Manager, CocoaPods, and Carthage.

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", from: "3.0.0")
```

Or in Xcode: **File → Add Packages** and enter the repository URL.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CDMarkdownKit', '~> 3.0'
```

Run `pod install`.

### Carthage

Add to your `Cartfile`:

```
github "chrisdhaan/CDMarkdownKit" ~> 3.0
```

Run `carthage update`.

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

### Preserving Leading Whitespace

By default, CDMarkdownKit strips leading whitespace (spaces and tabs) from each line. This is suitable for most Markdown text, but if you need to preserve indentation in code blocks or other contexts, enable the `preserveLeadingWhitespace` option:

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

**Note**: This setting only affects code elements. Other Markdown elements (bold, italic, lists, etc.) are not affected by this option.

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
| Tables | Pipe-delimited rows | Aligned columns |

### Platform Notes

| Feature | iOS | macOS | tvOS | watchOS | visionOS |
|---------|-----|-------|------|---------|----------|
| Bold / Italic / Strikethrough | ✓ | ✓ | ✓ | ✓ | ✓ |
| Headers | ✓ | ✓ | ✓ | ✓ | ✓ |
| Unordered Lists | ✓ | ✓ | ✓ | ✓ | ✓ |
| Ordered Lists | ✓ | ✓ | ✓ | ✓ | ✓ |
| Blockquotes | ✓ | ✓ | ✓ | ✓ | ✓ |
| Inline Code / Fenced Blocks | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tables | ✓ | ✓ | ✓ | ✓ | ✓ |
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

Cell content is rendered as plain text; inline formatting inside cells is not supported in this version.

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

VoiceOver will announce headings with their level ("Heading level 1: Introduction"),
helping users navigate document structure with the rotor.
