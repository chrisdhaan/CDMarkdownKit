# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

## Table of Contents

- [Unreleased](#unreleased)
- [5.0.0](#500)
- [4.2.1](#421)
- [4.2.0](#420)
- [4.1.0](#410)
- [4.0.3](#403)
- [4.0.2](#402)
- [4.0.1](#401)
- [4.0.0](#400)
- [3.3.0](#330)
- [3.2.0](#320)
- [3.1.0](#310)
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

## [Unreleased]

---

## [5.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/5.0.0)

Released on 2026-08-11.

### Removed

- Removed the deprecated synchronous `parse(_:)` overloads (`parse(_ markdown: String) -> NSAttributedString` and `parse(_ markdown: NSAttributedString) -> NSAttributedString`), deprecated since v3.2.0. Use the `async` `parse(_:)` overload instead — the signature is otherwise unchanged, so migration is adding `await` at each call site.

---

## [4.2.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.2.1)

Released on 2026-08-09.

### Fixed

- Fixed a catastrophic-backtracking regular expression used to parse inline code and fenced code blocks, which could freeze the app for seconds on realistic input, such as a document containing a single unclosed backtick.
- Fixed a fenced code block's rounded-corner background not extending under its own trailing newline when the block was the last thing in the document.
- Fixed blank lines inside fenced code blocks being silently deleted by the default newline-collapsing behavior.
- Fixed blank lines before a list item, when newline-collapsing is disabled, being miscounted as indentation and causing spurious list nesting.
- Fixed a Markdown table silently dropping extra cells from a ragged row that was wider than its header or first row.
- Fixed `CDMarkdownLabel`'s `attributedText` property not reflecting what was actually set when read back. As a result, `CDMarkdownLabel` now also correctly reports an intrinsic content size derived from its text, which was previously always absent — this may affect Auto Layout for existing consumers relying on the old always-zero-ish sizing behavior.
- Fixed `CDMarkdownNSTextView` never actually adopting its own rounded-corner-drawing layout manager and text storage. Creating one programmatically crashed during initialization; code span backgrounds never rendered; and using the view from a storyboard or XIB could leave any text that was set on it invisible, since it was written into a text storage the view never displayed.
- Fixed `CDMarkdownNSLabel` and `CDMarkdownNSTextView` not redrawing when their `roundAllCorners` property was toggled after the view had already been displayed, leaving rounded corners visually stale until some unrelated state change happened to force a redraw.
- Fixed `CDMarkdownNSTextView` never wrapping its text when created programmatically. Its text container was given no width, so every line ran off the right edge instead of wrapping, and resizing the view never re-wrapped the content.
- Hardened the default `CDMarkdownElement.parse()` loop so a custom element whose regular expression can produce a zero-length match can no longer cause parsing to loop indefinitely.
- Fixed `CDMarkdownTextView`'s `init(frame:textContainer:)` initializer not configuring the view, which silently dropped the library's rounded-corner background rendering for any caller constructing it directly instead of via `.makeTextView(frame:)` or a storyboard. `customTextStorage` on the TextKit 1 (iOS 15) fallback is now also populated on every `attributedText` assignment, consistent with `CDMarkdownLabel` and `CDMarkdownNSTextView`.

---

## [4.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.2.0)

Released on 2026-08-05.

### Removed
- CocoaPods distribution support (`CDMarkdownKit.podspec`, `Gemfile`,
  `Gemfile.lock`, the `pod lib lint` CI job, and all CocoaPods installation
  docs), ahead of CocoaPods Trunk going read-only on 2026-12-02. Swift
  Package Manager is now the sole supported distribution method. Existing
  CocoaPods installs will keep resolving indefinitely but will no longer
  receive updates — switch to SPM to continue getting new releases.

---

## [4.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.1.0)

Released on 2026-08-03.

### Added

- CI now runs the full test suite against real iOS, tvOS, and visionOS simulators, in addition to the existing build-only checks for those platforms.
- Replaced near-tautological `CDMarkdownText` SwiftUI tests (which only asserted the view's type) with real coverage of its parser-selection precedence and its `NSAttributedString`-to-`AttributedString` conversion, following the existing `CDMarkdownLabel` pattern of exposing testable seams as `internal` rather than adding a view-inspection dependency.
- Added test coverage for `CDMarkdownView` (previously untested), covering parser-selection precedence and link-tap handling on both the iOS/tvOS/visionOS and macOS variants, plus iOS/tvOS/visionOS-specific text-view configuration, following the same "expose testable seams as `internal`" pattern used for `CDMarkdownText`.

### Changed

- Collapsed `CDMarkdownLabel`'s three independent TextKit 2 state properties (`tk2LayoutManager`, `tk2ContentStorage`, `tk2LayoutDelegate`) into a single atomic `tk2Stack`, so every dispatch site checks one thing instead of downcasting whichever of the three it happens to need — eliminating a bug class where the three could drift out of sync.
- The parser's leading-whitespace handling now dedents rather than stripping every line outright: only whitespace common to every line is removed, so relative indentation between lines is preserved. This means indentation-based nested unordered lists now work under the parser's default settings, without needing to opt in via `preserveLeadingWhitespace`.

### Fixed

- Fixed several test files failing to compile for visionOS, due to a platform check that predated visionOS support and was never updated to include it.
- Fixed `CDMarkdownLabel` rendering garbled, overlapping text on iOS/tvOS 16+ whenever its content was taller than the label's own bounds, such as a fixed-height label without a scroll view. TextKit 2 fragments beyond what fit the container were drawn at the wrong position instead of being cleanly excluded.
- Fixed `CDMarkdownLabel`/`CDMarkdownTextView`'s `roundAllCorners` flag not retroactively rounding already-displayed code and syntax backgrounds on TextKit 2 (iOS/tvOS 16+) when toggled after `attributedText` had already been laid out. The corner-rounding flag is now read live at draw time instead of being cached on each text layout fragment when it was created, matching the behavior already present on the TextKit 1 fallback.
- Fixed Markdown tables measuring a column's width from its escaped, not rendered, cell text, so a column containing inline code was sized far too wide and threw off tab-stop alignment for any columns after it. Fixed alongside a related, more severe bug where inline code inside a table cell rendered as leftover escaped placeholder text instead of the original code.
- Fixed indented blockquotes and indented ordered-list items failing to parse under the parser's default settings, a regression introduced by the leading-whitespace dedent change above — both elements' marker regexes assumed markers were always flush-left.

---

## [4.0.3](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.0.3)

Released on 2026-07-31.

### Fixed

- Fixed `CDMarkdownLabel` never rendering any text on iOS and tvOS 16+. Its TextKit 2 setup checked a freshly created content storage for a layout manager it hadn't created yet, so the check always failed and the label silently never configured itself.
- Fixed link tap hit-testing on `CDMarkdownLabel`'s TextKit 1 (iOS 15) fallback failing to register whenever the label's frame was taller than its displayed text, due to a missing coordinate-space adjustment present on the TextKit 2 path but not the TextKit 1 one.

### Added

- Added test coverage for the TextKit 2 rendering path: `CDMarkdownLabel`/`CDMarkdownTextView`'s TextKit 1/TextKit 2 configuration branching, link tap hit-testing, rounded-corner background drawing (including regression coverage for bugs fixed in 4.0.2), and `roundAllCorners` propagation.

---

## [4.0.2](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.0.2)

Released on 2026-07-24.

### Fixed

- Fixed link and image URLs containing parentheses (e.g. `[text](https://example.com/(path))`) being truncated at the first inner `)` instead of the matching closing paren.
- Fixed image attachments never becoming tappable — the `.link` attribute was being applied with the wrong delimiter and was silently dropped.
- Fixed an off-by-one in list and blockquote nesting depth that added an extra, unwanted indent level to top-level (non-nested) lists and blockquotes.
- Added support to `CDMarkdownList` for indentation-based nested lists when `preserveLeadingWhitespace` is set to `true` on the parser.
- Fixed inline code spans and fenced code blocks silently losing styling on any content after an emoji or other astral-plane character, caused by measuring styled ranges in `Character` counts instead of UTF-16 code units.
- Fixed backslash-escaped emoji round-tripping into replacement characters (`�`) instead of the original character.
- Fixed `squashNewlines` and reference-link-definition stripping not recognizing Windows-style (CRLF) line endings, leaving blank lines unsquashed and reference definitions unstripped in CRLF-authored documents.
- Fixed reference-definition-looking lines inside an unclosed code fence being incorrectly stripped as if they were real reference definitions.
- Fixed a crash when setting `CDMarkdownLabel.attributedText = nil`.
- Fixed `CDMarkdownTextView`'s iOS 15 (TextKit 1) fallback losing its layout manager on the second and later `attributedText` update, after the first update had already replaced it.
- Fixed TextKit 2 rounded-corner code-block backgrounds painting the entire line instead of just the code span, and fixed backgrounds not rendering correctly for paragraphs after the first.
- Fixed link tap hit-testing being inconsistent between the TextKit 1 and TextKit 2 rendering paths.
- Fixed the TextKit 1 fallback's word-break-inside-URL prevention never activating because its layout manager delegate was never assigned.
- Fixed `CDColor.isEqualTo` risking a crash when comparing an atypical monochrome `CGColor`.
- Fixed `header.color` set via a `CDMarkdownTheme` not falling back to the parser's default color when the theme left it unspecified, unlike every other themed element.

---

## [4.0.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.0.1)

Released on 2026-06-15.

### Fixed

- Fixed infinite recursion in `CDColor.label` on iOS, tvOS, watchOS, and visionOS. The property was defined in an extension on `CDColor` (a typealias for `UIColor`) and called `UIColor.label`, which resolved back to itself. The extension now only defines `label` on macOS where `NSColor.labelColor` requires bridging; on Apple's other platforms `UIColor.label` is used directly.

---

## [4.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/4.0.0)

Released on 2026-06-15.

### Added

- Added `CDMarkdownTextLayoutDelegate` (in `CDMarkdownTextLayoutManager.swift`), an `NSTextLayoutManagerDelegate` assigned to the stock `NSTextLayoutManager` used by `CDMarkdownLabel` and `CDMarkdownTextView` on iOS/tvOS 16+. Delegates fragment creation to `CDMarkdownTextLayoutFragment` and exposes a `roundAllCorners` property that propagates to each fragment.
- Added `CDMarkdownTextLayoutFragment`, a custom `NSTextLayoutFragment` subclass that draws rounded-corner backgrounds for code and syntax spans in the TextKit 2 rendering path. Reads the `.backgroundColor` attribute from text storage at draw time so code and syntax blocks each use their correct color.
- Added TextKit 2 rendering path to `CDMarkdownLabel` on iOS/tvOS 16+. Text layout, rect measurement, glyph-position calculation, and link hit-testing all use `NSTextLayoutManager` when TextKit 2 is active; TextKit 1 fallback is preserved for iOS/tvOS 15.
- Added TextKit 2 rendering path to `CDMarkdownTextView` on iOS/tvOS 16+. `configureTK2()` assigns a `CDMarkdownTextLayoutDelegate` to the view's stock `NSTextLayoutManager`; `configureTK1()` continues to install `CDMarkdownLayoutManager` on iOS/tvOS 15.
- Added `CDMarkdownTextView.makeTextView(frame:)` public factory method. Preferred way to construct a `CDMarkdownTextView` programmatically — selects TextKit 2 on iOS/tvOS 16+ and TextKit 1 on iOS/tvOS 15 automatically.

### Changed

- Raised minimum deployment targets:
  - iOS: 12.0 → 13.0
  - macOS: 10.13 → 10.15
  - tvOS: 12.0 → 13.0
  - watchOS: 4.0 → 6.0
- Improved Swift 6 strict concurrency: removed `@preconcurrency` imports, `@unchecked Sendable` conformances, and `nonisolated(unsafe)` from parser properties; added `@MainActor` to all sixteen element classes and base protocol declarations; added `@MainActor` to the `NSLayoutManagerDelegate` extension.
- Replaced `DispatchQueue.main.asyncAfter` with `Task.sleep` in the async parsing pipeline to align with structured Swift concurrency.

---

## [3.3.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.3.0)

Released on 2026-06-07.

### Added

- Added `cdMarkdownCodeLanguage` attribute key. Applied to fenced code block ranges when a language hint is present (e.g. ` ```swift `). Value is a `String` containing the language identifier exactly as written after the opening fence.
- Added `CDMarkdownLinkReference` element for parsing reference-style links (`[text][ref]` with `[ref]: url` definitions). Reference definitions are stripped from the rendered output and resolved to `.link` attributes at parse time.
- Added `cdMarkdownLinkTitle` attribute key for the optional title string from a reference link definition. Value is a `String` (without surrounding quotes or parentheses). Present only when the definition included a title.
- Added `CDMarkdownTheme` struct for unified styling of all parser elements. Bundles font, color, and per-element overrides (`HeaderTheme`, `InlineTheme`, `LinkTheme`) into a single value.
- Added `CDMarkdownTheme.default` and `CDMarkdownTheme.systemDark` static factory themes.
- Added `CDMarkdownParser.init(theme:)` convenience initializer that configures the parser from a `CDMarkdownTheme`.
- Added theme convenience initializers to `CDMarkdownView` and `CDMarkdownText`.
- Added `markdownTheme` SwiftUI environment key and `.markdownTheme(_:)` view modifier so a theme can be injected into an entire view hierarchy.
- Added iOS 17+ `textView(_:primaryActionFor:defaultAction:)` delegate method to `CDMarkdownView.Coordinator` for correct link-tap behaviour on visionOS and iOS 17+.

### Fixed

- Fixed reference link definitions inside fenced code blocks being incorrectly extracted as link definitions.
- Fixed `UITextItemInteraction` deprecation warning on visionOS.
- Fixed `CDMarkdownText` not re-parsing when the `markdownTheme` environment value changes.

---

## [3.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.2.0)

Released on 2026-05-31.

### Added

- Added Swift 6 language mode (`swiftLanguageModes: [.v6]`) to `Package.swift`.
- Added `CDMarkdownTaskList` element for parsing GFM task list items (`- [ ]` / `- [x]`).
- Added `CDMarkdownHorizontalRule` element for parsing horizontal rules (`---`, `***`, `___`).
- Added inline markdown parsing inside GFM table cells (bold, italic, links, inline code).
- Added `disabledElementTypes`, `disable(_:)`, and `enable(_:)` to `CDMarkdownParser` for opting out of individual default elements.
- Added `insertCustomElement(_:before:)` and `insertCustomElement(_:after:)` to `CDMarkdownParser` for precise pipeline positioning.
- Added accessibility attribute keys (`cdMarkdownHeadingLevel`, `cdMarkdownIsCode`, `cdMarkdownIsBlockquote`) and `accessibilityAttributedString(from:)` helper on `CDMarkdownParser`.
- Added `CDMarkdownNSLayoutManager`, `CDMarkdownNSTextView`, and `CDMarkdownNSLabel` — AppKit UI components for macOS.
- Added `CDMarkdownText` and `CDMarkdownView` — SwiftUI wrappers for iOS, tvOS, macOS, watchOS, and visionOS.
- Added `markdownParser` SwiftUI environment key and `.markdownParser(_:)` view modifier.

### Updated

- Deprecated synchronous `parse(_:)` overloads in favour of the async overloads.

---

## [3.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.1.0)

Released on 2026-05-12.

### Added

- Added `CDMarkdownOrderedList` element for parsing ordered (numbered) lists.
- Added `CDMarkdownTable` element for parsing GitHub Flavored Markdown pipe tables.
- Added `preserveLeadingWhitespace` configuration property to `CDMarkdownParser`. When `true`, leading whitespace is preserved in inline code spans and fenced code blocks.
- Added visionOS platform support to `Package.swift`, `CDMarkdownKit.podspec`, all source file platform guards, and CI.
- Added native DocC documentation catalog (`Source/CDMarkdownKit.docc/`) with landing page and Getting Started article.

### Updated

- Migrated documentation hosting from Jazzy to DocC. Removed `.jazzy.yaml` and the `jazzy` gem; added `swift-docc-plugin` dependency to `Package.swift`; regenerated `docs/` with DocC static site output.
- Extended inline doc comments across all source files for full DocC compatibility.
- Updated CI to add a visionOS build job and replace the Jazzy documentation job with a DocC build job.

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
