# Getting Started

Parse Markdown and display it in your app in three steps.

## Parse a string

Create a ``CDMarkdownParser`` and call `parse(_:)`:

```swift
let parser = CDMarkdownParser()
let attributed = await parser.parse("Hello **world**")
```

## Display with CDMarkdownLabel

```swift
let label = CDMarkdownLabel(frame: .zero)
label.attributedText = await parser.parse("Hello **world**")
```

## Display with CDMarkdownTextView

```swift
let textView = CDMarkdownTextView(frame: view.bounds, textContainer: nil)
textView.configure()
textView.attributedText = await parser.parse("Hello **world**")
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
