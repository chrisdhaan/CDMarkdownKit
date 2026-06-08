# CDMarkdownKit 4.0 Migration Guide

This guide covers the breaking changes in CDMarkdownKit 4.0 and how to update your code.

---

## Raised Deployment Targets

CDMarkdownKit 4.0 increases the minimum deployment targets across all platforms:

| Platform | 3.3.0  | 4.0.0  | Change |
|----------|--------|--------|--------|
| iOS      | 12.0+  | 13.0+  | +1.0   |
| macOS    | 10.13+ | 10.15+ | +0.2   |
| tvOS     | 12.0+  | 13.0+  | +1.0   |
| watchOS  | 4.0+   | 6.0+   | +2.0   |
| Swift    | 5.3+   | 5.3+   | No change |

**Action required:** If your app targets earlier OS versions, update your deployment target in your project settings or `Package.swift` manifest.

---

## TextKit 2 Rendering (iOS/tvOS 16+)

CDMarkdownKit 4.0 migrates `CDMarkdownLabel` and `CDMarkdownTextView` to TextKit 2 (`NSTextLayoutManager`) on iOS/tvOS 16+. TextKit 1 (`NSLayoutManager`) remains the fallback on iOS/tvOS 15.

### What changed

- `CDMarkdownLabel` now uses `CDMarkdownTextLayoutManager` internally on iOS 16+. All layout, text rect measurement, and link hit-testing go through the TextKit 2 path.
- `CDMarkdownTextView` installs `CDMarkdownTextLayoutManager` on iOS 16+ via `makeTextView(frame:)` or `configure()`.
- Rounded-corner backgrounds are drawn by `CDMarkdownTextLayoutFragment` in the TextKit 2 path, replacing the `NSLayoutManager`-based drawing in `CDMarkdownLayoutManager`.

### Constructing CDMarkdownTextView

Use the new public factory method for programmatic construction:

```swift
// CDMarkdownKit 4.0 — Preferred
let textView = CDMarkdownTextView.makeTextView(frame: frame)
textView.roundAllCorners = true
```

The factory automatically selects TextKit 2 on iOS 16+ and TextKit 1 on iOS 15.

The existing initializers still work:

```swift
// CDMarkdownKit 4.0 — Still valid
let textView = CDMarkdownTextView(frame: frame, textContainer: nil)
textView.configure()
```

### Rounded corners

The `roundAllCorners` API is unchanged. Setting it on `CDMarkdownLabel` or `CDMarkdownTextView` propagates automatically to the correct renderer (TK2 or TK1):

```swift
// Unchanged in 4.0
label.roundAllCorners = true
textView.roundAllCorners = true
```

No code changes are required unless you were directly subclassing `CDMarkdownLayoutManager` and relying on the drawing callbacks. If so, override `CDMarkdownTextLayoutFragment.draw(at:in:)` to extend TK2 behavior.

---

## Swift 6 Strict Concurrency

CDMarkdownKit 4.0 removes the remaining concurrency workarounds introduced in 3.x:

- `@preconcurrency` imports removed
- `@unchecked Sendable` conformances removed from `CDMarkdownParser`, `CDMarkdownLabel`, and `CDMarkdownTextView`
- `nonisolated(unsafe)` removed from parser properties
- `@MainActor` added to all element classes, base protocol declarations, and the `NSLayoutManagerDelegate` extension

**Impact:** If your code passed parser instances across concurrency domains or stored them in `nonisolated` contexts, you may see new Swift 6 concurrency errors at the call site. The fix in all cases is to ensure parser access happens on `@MainActor` (or within an actor that owns the parser).

```swift
// Correct in 4.0 — access parser on main actor
@MainActor
func parseAndDisplay(_ markdown: String) async {
    let result = await parser.parse(markdown)
    label.attributedText = result
}
```

---

## Unchanged

- All public parsing APIs (`CDMarkdownParser`, element classes, `CDMarkdownTheme`)
- `CDMarkdownLabel` and `CDMarkdownTextView` property names
- SwiftUI components (`CDMarkdownText`, `CDMarkdownView`)
- macOS components (`CDMarkdownNSTextView`, `CDMarkdownNSLabel`)
- Import statement — `import CDMarkdownKit` is unchanged

---

## Checklist

Before deploying your updated app:

- [ ] Updated deployment targets in project settings or `Package.swift`
- [ ] Replaced direct `CDMarkdownTextView(frame:textContainer:)` construction with `CDMarkdownTextView.makeTextView(frame:)` where possible
- [ ] Verified `@MainActor` usage at parser call sites if you see new Swift 6 concurrency diagnostics
- [ ] Re-ran your test suite to catch any edge cases
- [ ] Verified UI rendering — particularly rounded-corner code blocks on iOS 16+ devices

---

## Questions or Issues?

If you encounter problems during migration, please:
- Check [Documentation/Usage.md](Usage.md) for current API examples
- Search existing [GitHub Issues](https://github.com/chrisdhaan/CDMarkdownKit/issues)
- Open a new issue with details about your use case
