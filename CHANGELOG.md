# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

## Table of Contents

- [3.0.0](#300)
- [2.5.1](#251)
- [2.5.0](#250)
- [2.4.0](#240)
- [2.3.0](#230)
- [2.2.0](#220)
- [2.1.1](#211)
- [2.1.0](#210)
- [2.0.0](#200)
- [1.2.1](#121)
- [1.2.0](#120)
- [1.1.0](#110)
- [1.0.0](#100)

---

## [3.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.0.0)

Released on 2026-05-10.

### Added

- Async image loading with `async/await` support via overloaded `parse(_:)` method
- Swift 6 concurrency safety: `@MainActor` annotations on UI components and `Sendable` conformances
- Comprehensive unit test suite with Swift Testing framework
- GFM ordered list support (`1.`, `2.`, `3.`)
- GFM table support with column alignment
- Public API documentation with Jazzy
- GitHub Pages hosted documentation at https://chrisdhaan.github.io/CDMarkdownKit/
- `Documentation/Usage.md` with comprehensive usage examples and platform-specific notes
- Privacy manifest (`PrivacyInfo.xcprivacy`) for App Store compliance
- SwiftLint enforcement in CI

### Updated

- Deployment targets: iOS 12.0+, macOS 10.13+, tvOS 12.0+, watchOS 4.0+
- CI/CD pipeline: Xcode 26.1.1–26.4.1 (macos-26) + Xcode 16.4 (macos-15), modern GitHub Actions, xcbeautify output formatting
- Swift Package Manager: Consolidated versioned manifests, added dynamic library product
- CocoaPods support: Updated deployment targets, added resource bundles, enforced CocoaPods 1.13+
- Documentation: Restructured README as navigation hub, added migration guide
- Rounded corner styling: Replaced `roundCodeCorners`/`roundSyntaxCorners` with unified attribute-based approach
- `CDMarkdownStyle` protocol now includes `strikethroughColor` and `strikethroughStyle`

### Fixed

- URL ranges accumulating across multiple `attributedText` assignments in `CDMarkdownLabel`
- Hardcoded color comparison breaking custom color support in `CDMarkdownLayoutManager`
- `CDMarkdownStrikethrough` styling inconsistency by adding properties to `CDMarkdownStyle` protocol
- `CDMarkdownAutomaticLink` crash on watchOS by returning no-op regex
- `CDMarkdownLink` regex failing at string position 0 and incorrectly excluding characters with negative lookbehind
- Force unwrap crash in `CDFont.withTraits(_:)` when fonts lack bold/italic variants
- `CDMarkdownTextView.shouldInteractWith` delegate method never called due to missing `super.attributedText` assignment
- Language hints in fenced code blocks rendering as content instead of being silently stripped
- Missing force unwrap crash protection and graceful fallback for unavailable font traits
- `CDMarkdownImage` regex `[!{1}]` incorrectly matching `{`, `1`, and `}` in addition to `!`, causing false positive image detection
- Async `parse(_:)` overloads declared `public` instead of `open`, preventing subclasses from overriding the async parse path
- Async image loading using the iOS 15-only `URLSession.data(from:)` API; replaced with a back-deployed wrapper available from iOS 13 / macOS 10.15 / tvOS 13 / watchOS 6
- Synchronous `parse(_:NSAttributedString)` overload triggering network requests on the calling thread; it now always skips image loading
- `CDMarkdownLabel` text container initialized with `maximumNumberOfLines = 1` (UILabel default), silently truncating all multi-line markdown to a single line
- `CDMarkdownLabel` `NSLayoutManagerDelegate` conformance producing a Swift 6 data race warning; resolved with `@preconcurrency`
- Leading whitespace strip regex `^\s+` consuming blank lines, causing `squashNewlines = false` to still collapse consecutive newlines; corrected to `^[ \t]+`

---

## [2.5.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.5.1)

Released on 2022-12-13.

### Added

- Swift 5.7

### Updated

- CI: Tests device, platform, Xcode, and SDK versions

---

## [2.5.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.5.0)

Released on 2022-12-12.

### Added

- Underline color and style on all elements

---

## [2.4.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.4.0)

Released on 2022-12-03.

### Added

- Strikethrough

---

## [2.3.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.3.0)

Released on 2022-10-17.

### Added

- `squashNewlines` parameter

---

## [2.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.2.0)

Released on 2022-06-26.

### Added

- Swift 5.4, 5.5, and 5.6

### Updated

- Swift Package Manager: Minimum Swift version 5.3
- CI: Tests device, platform, Xcode, and SDK versions

---

## [2.1.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.1.1)

Released on 2021-05-29.

### Updated

- Markdown Parsing: Bold and italic parsing by character
- Swift Package Manager: Built with `swift-tools-version:5.1`

---

## [2.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.1.0)

Released on 2020-08-30.

### Added

- Swift 5.1

---

## [2.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.0.0)

Released on 2020-08-29.

### Added

- Swift 5.0

---

## [1.2.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.2.1)

Released on 2018-12-14.

### Added

- Swift 4.2
- Swift 4.0
  - `Dictionary+CDMarkdownKit`, `NSAttributedString+CDMarkdownKit`, `NSMutableAttributedString+CDMarkdownKit`, `NSTextCheckResult+CDMarkdownKit`, and `NSTextStorage+CDMarkdownKit` extensions
- iOS Example: `CDApplicationLaunchOptionsKey`, `CDLayoutConstraintAttribute`, and `CDLayoutConstraintRelation` typealias'

### Updated

- Swift 4.0: Extensions assume responsibility for `swift()` macro from classes
- `CDAttributesKey` becomes `CDAttributedStringKey`

---

## [1.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.2.0)

Released on 2018-07-27.

### Added

- Platform Support: macOS: `CDFont+CDMarkdownKit` `withSize` method that uses `NSFontManager` to correctly set system fonts dynamically based on size
- Swift 4.0: `CDAttributesKey` for correctly configuring `NSAttributedString` attribute dictionary keys
- SwiftLint

### Updated

- UITextView With Markdown Formatting: Code example to use `NSLayoutConstraints` to correctly set `intrinsicContentSize`
- Platform Support: macOS: `CDFont+CDMarkdownKit` `bold` and `italic` methods to use `NSFontManager` opposed to `CDFontDescriptorSymbolicTraits`

---

## [1.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.1.0)

Released on 2018-06-12.

### Added

- Swift 4.0

---

## [1.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.0.0)

Released on 2018-06-11.

### Added

- Markdown Parsing: Italic, Bold, Header, Quote, List, Code, Syntax, Link, Image
- UITextView With Markdown Formatting
- UILabel With Markdown Formatting
- Platform Support: iOS, macOS, tvOS, watchOS
- Documentation

---
