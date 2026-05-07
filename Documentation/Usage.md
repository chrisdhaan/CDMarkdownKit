# CDMarkdownKit Usage Guide

## Basic Setup

Initialize a parser with default settings:

```swift
let parser = CDMarkdownParser()
let markdown = "Hello **world**"
let attributed = parser.parse(markdown)
```

## CDMarkdownParser

`CDMarkdownParser` is the main entry point for parsing Markdown into `NSAttributedString`.

### Configuration

The parser accepts several configuration options at initialization:

```swift
let parser = CDMarkdownParser(
    font: UIFont.systemFont(ofSize: 16),
    boldFont: UIFont.boldSystemFont(ofSize: 16),
    italicFont: UIFont.italicSystemFont(ofSize: 16),
    fontColor: UIColor.black,
    backgroundColor: UIColor.white,
    paragraphStyle: nil,
    imageSize: CGSize(width: 320, height: 480),
    automaticLinkDetectionEnabled: true,
    squashNewlines: true
)
```

### Synchronous Parsing

The synchronous `parse(_:)` method is the standard way to parse Markdown:

```swift
let input = "# Hello\n\nThis is **bold** text."
let result = parser.parse(input)
label.attributedText = result
```

**⚠️ Note on Image Loading**: When `CDMarkdownImage` elements are present with remote URLs, the synchronous `parse(_:)` method blocks the calling thread for the duration of each network request. For documents with remote images, consider using the async variant to avoid blocking the main thread.

### Async Parsing (v3.0+)

For non-blocking image loading, use the async `parse(_:)` overload. This method defers image loading until after parsing completes, allowing images to be fetched concurrently without blocking:

```swift
let input = "# Title\n\n![alt text](https://example.com/image.png)\n\nMore text here."

Task {
    let result = await parser.parse(input)
    DispatchQueue.main.async {
        self.label.attributedText = result
    }
}
```

The async variant:
- Parses Markdown synchronously on the calling thread
- Defers all image loading (remote URLs) until after parsing
- Fetches images concurrently via `URLSession.shared.data(from:)`
- Maintains proper attribution and sizing from the parser configuration
- Returns to the main thread via the Task context

**When to use async parsing:**
- Documents with multiple remote images
- Performance-critical contexts where blocking is unacceptable
- Loading Markdown from network sources
- Rendering large documents

**When synchronous parsing is fine:**
- Simple documents without images
- Documents with only local/bundled images
- One-off parsing operations

---

## Supported Syntax

CDMarkdownKit supports a subset of Markdown syntax:

- **Bold**: `**text**` or `__text__`
- **Italic**: `*text*` or `_text_`
- **Strikethrough**: `~~text~~`
- **Headers**: `# H1` through `###### H6`
- **Lists**: `* item`, `- item`, `+ item`
- **Blockquotes**: `> quote text`
- **Inline Code**: `` `code` ``
- **Fenced Code Blocks**: ` ```language\ncode\n``` `
- **Links**: `[text](url)`
- **Automatic Links**: `https://example.com` (detected automatically)
- **Images**: `![alt](url)` — iOS/macOS/tvOS only
- **Tables**: GFM-style tables (GitHub Flavored Markdown)

---

## CDMarkdownLabel

`CDMarkdownLabel` is a `UILabel` subclass that renders Markdown with tap-to-open-URL support:

```swift
let label = CDMarkdownLabel()
label.delegate = self
label.attributedText = parser.parse("Visit [GitHub](https://github.com)")
```

Implement `CDMarkdownLabelDelegate` to handle link taps:

```swift
extension MyViewController: CDMarkdownLabelDelegate {
    func didSelect(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
```

---

## CDMarkdownTextView

`CDMarkdownTextView` is a `UITextView` subclass with optional rounded-corner backgrounds for code blocks:

```swift
let textView = CDMarkdownTextView()
textView.attributedText = parser.parse(markdown)
textView.isSelectable = true  // Required for link interaction
```

Link interaction is available via `UITextViewDelegate`:

```swift
extension MyViewController: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        // Handle link tap
        return false
    }
}
```

---

## Styling

All elements can be styled by accessing the parser's element properties. Each element conforms to `CDMarkdownStyle`:

```swift
parser.bold.color = UIColor.red
parser.italic.color = UIColor.blue
parser.header.font = UIFont.preferredFont(forTextStyle: .title1)
```

Style properties:
- `font`: Display font
- `color`: Text color
- `backgroundColor`: Background color
- `paragraphStyle`: `NSParagraphStyle` for spacing, alignment, indentation
- `underlineColor` / `underlineStyle`: Underline appearance
- `strikethroughColor` / `strikethroughStyle`: Strikethrough appearance (bold/italic/strikethrough)

---

## Custom Elements

Register custom Markdown element types with the parser:

```swift
class CDMarkdownHighlight: CDMarkdownElement, CDMarkdownStyle {
    var regex: String { "==(.+?)==" }
    var font: CDFont?
    var color: CDColor? = .yellow
    var backgroundColor: CDColor?
    var paragraphStyle: NSParagraphStyle?
    var underlineColor: CDColor?
    var underlineStyle: NSUnderlineStyle?
    
    func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex)
    }
    
    func match(_ match: NSTextCheckingResult,
               attributedString: NSMutableAttributedString) {
        // Handle the match
    }
}

let highlight = CDMarkdownHighlight()
parser.customElements = [highlight]
```

---

## Platform Notes

### watchOS

`CDMarkdownKit` on watchOS supports text styling but not tappable links or images:
- All text styling (bold, italic, headers, code, strikethrough) works
- Links are styled but not tappable
- Images are not supported
- Use `WKInterfaceLabel.setAttributedText(_:)` to display

### macOS

`CDMarkdownKit` on macOS supports all features including images and link interaction through `NSTextViewDelegate`.

### Catalyst

Full support via the iOS code path.

---

## Advanced Usage

### Preserving Newlines

By default, consecutive newlines are squashed to a single newline. Disable this:

```swift
parser.squashNewlines = false
```

### Automatic Link Detection

Bare URLs like `https://example.com` are detected and converted to tappable links. Disable this:

```swift
parser.automaticLinkDetectionEnabled = false
```

### Custom Paragraph Styles

Apply custom spacing and alignment:

```swift
let style = NSMutableParagraphStyle()
style.paragraphSpacing = 8
style.paragraphSpacingBefore = 4
style.alignment = .center

let parser = CDMarkdownParser(paragraphStyle: style)
```

---

## Troubleshooting

**Images not loading**: Ensure the image URL is valid and reachable. For async parsing, images are loaded via `URLSession.shared.data(from:)`, which requires network access.

**Custom fonts not working**: Some custom fonts may not have bold or italic variants. `CDMarkdownKit` gracefully falls back to the base font if the variant is unavailable.

**Links not tapping on CDMarkdownTextView**: Ensure `isSelectable` is `true` on the text view and a delegate is set.
