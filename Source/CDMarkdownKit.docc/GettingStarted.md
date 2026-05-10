# Getting Started

Parse Markdown and display it in your app in three steps.

## Parse a string

Create a ``CDMarkdownParser`` and call ``CDMarkdownParser/parse(_:)-string``:

```swift
let parser = CDMarkdownParser()
let attributed = parser.parse("Hello **world**")
```

## Display with CDMarkdownLabel

```swift
let label = CDMarkdownLabel()
label.markdownParser = parser
label.parseText = "Hello **world**"
```

## Display with CDMarkdownTextView

```swift
let textView = CDMarkdownTextView.makeTextView(frame: view.bounds)
textView.attributedText = parser.parse("Hello **world**")
```

## Async parsing with image support

For strings that contain image references, use the async overload so images are
downloaded off the main thread:

```swift
Task {
    let attributed = await parser.parse("![logo](https://example.com/logo.png)")
    label.attributedText = attributed
}
```
