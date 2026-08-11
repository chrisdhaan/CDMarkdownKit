# CDMarkdownKit 3.0 Migration Guide

This guide covers the breaking changes in CDMarkdownKit 3.0 and how to update your code.

---

## Raised Deployment Targets

CDMarkdownKit 3.0 increases the minimum deployment targets across all platforms:

| Platform | 2.5.1 | 3.0.0 | Change |
|----------|-------|-------|--------|
| iOS      | 10.0+ | 11.0+ | +1.0  |
| macOS    | 10.12+ | 10.13+ | +0.1  |
| tvOS     | 10.0+ | 11.0+ | +1.0  |
| watchOS  | 3.0+  | 4.0+  | +1.0  |
| Swift    | 5.3+  | 5.3+  | No change |

**Action required:** If your app targets earlier OS versions, you must update your deployment target in your project settings or `Package.swift` manifest.

---

## Changed: Rounded Corner Styling

### Removal of `roundCodeCorners` and `roundSyntaxCorners`

In CDMarkdownKit 2.5.1, `CDMarkdownLayoutManager` provided two boolean properties to control rounded corners:

```swift
// CDMarkdownKit 2.5.1 — DEPRECATED
layoutManager.roundCodeCorners = true
layoutManager.roundSyntaxCorners = true
```

In CDMarkdownKit 3.0, these properties have been removed in favor of a unified `roundAllCorners` property that uses an attribute-based approach:

```swift
// CDMarkdownKit 3.0 — NEW
layoutManager.roundAllCorners = true
```

The new attribute-based approach applies rounded corners to all background-colored ranges, regardless of element type. If you need fine-grained control over which elements have rounded corners, use the `.cdMarkdownRoundedBackground` attribute when creating custom elements.

**Migration:**
- Replace `roundCodeCorners = true` and `roundSyntaxCorners = true` with `roundAllCorners = true`
- If you relied on the old properties, switch to `roundAllCorners` for a simpler API
- For `CDMarkdownLabel` and `CDMarkdownTextView`, the property names remain the same (internally mapped to `roundAllCorners`)

---

## New: Async Image Loading

### New Async `parse(_:)` Overload

CDMarkdownKit 3.0 introduces an async variant of the parsing method for non-blocking image loading:

```swift
// CDMarkdownKit 2.5.1 — Synchronous (blocks on remote images)
let attributedString = parser.parse(markdown)

// CDMarkdownKit 3.0 — Asynchronous (loads images in background)
let attributedString = await parser.parse(markdown)
```

**Note:**

`parse(_:)` is `async` regardless of whether the document has images — local-only Markdown still parses effectively instantly. The synchronous overloads shown above were removed in a later major version; see `CHANGELOG.md`.

**Migration:**

If you're parsing Markdown with remote images, wrap the call in a `Task`:

```swift
Task {
    let attributedString = await parser.parse(markdownWithImages)
    DispatchQueue.main.async {
        self.label.attributedText = attributedString
    }
}
```

The synchronous overloads were later removed entirely (see `CHANGELOG.md`); all callers must now use the `async` form shown above.

---

## Changed: Strikethrough Styling

### `strikethroughColor` and `strikethroughStyle` Now on `CDMarkdownStyle`

In CDMarkdownKit 2.5.1, strikethrough color and style were properties only on `CDMarkdownStrikethrough`. In 3.0, they are now part of the `CDMarkdownStyle` protocol, allowing all elements to use strikethrough if desired.

**Good news:** Your existing code continues to work. The properties default to `nil`, so existing `CDMarkdownStrikethrough` customizations remain unchanged:

```swift
// Both 2.5.1 and 3.0 — Still works
parser.strikethrough.strikethroughColor = UIColor.red
parser.strikethrough.strikethroughStyle = .double
```

No migration is required unless you want to apply strikethrough to other elements:

```swift
// CDMarkdownKit 3.0 — NEW: Apply strikethrough to bold text
parser.bold.strikethroughColor = UIColor.gray
parser.bold.strikethroughStyle = .single
```

---

## Removed: Carthage Support

CDMarkdownKit 3.0 removes support for Carthage as a distribution method. Carthage is no longer actively maintained and has limited adoption in the Swift community.

**Supported installation methods in 3.0:**
- **Swift Package Manager** (recommended)
- **CocoaPods**

**Migration:** If you were using Carthage, switch to Swift Package Manager or CocoaPods:

```swift
// Swift Package Manager
.package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", from: "3.0.0")
```

```ruby
# CocoaPods
pod 'CDMarkdownKit', '~> 3.0'
```

---

## Unchanged: Import Statements

No changes are required to your import statements. The module name and public API remain the same:

```swift
import CDMarkdownKit  // No changes
```

All public classes and protocols maintain backward compatibility with their names and signatures.

---

## Swift Concurrency (Swift 6 Support)

CDMarkdownKit 3.0 adds Swift 6 concurrency safety with `@MainActor` annotations on UI components and `Sendable` conformances on core protocols. This should not affect most code, but if you encounter strict concurrency warnings:

- Ensure you call `CDMarkdownLabel` and `CDMarkdownTextView` methods from the main thread
- The parser itself is not `Sendable` — create per-thread instances if needed in concurrent code

---

## Checklist

Before deploying your updated app:

- [ ] Updated deployment targets in your project settings or `Package.swift`
- [ ] Replaced `roundCodeCorners`/`roundSyntaxCorners` with `roundAllCorners` (if used)
- [ ] Wrapped async image parsing in a `Task` or `async` context (if needed)
- [ ] Re-ran your test suite to catch any edge cases
- [ ] Verified UI rendering with the new async parsing behavior

---

## Questions or Issues?

If you encounter problems during migration, please:
- Check [Documentation/Usage.md](Usage.md) for current API examples
- Search existing [GitHub Issues](https://github.com/chrisdhaan/CDMarkdownKit/issues)
- Open a new issue with details about your use case
