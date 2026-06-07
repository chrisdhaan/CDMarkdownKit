# CDMarkdownKit — Claude Guide

## Project Overview

CDMarkdownKit is a pure-Swift, zero-dependency framework for parsing Markdown text into `NSAttributedString`. It supports rendering inside custom `UILabel` and `UITextView` subclasses with optional rounded-corner background styling for code and syntax blocks.

- **Current version**: 3.3.0
- **License**: MIT
- **Author**: Christopher de Haan (contact@christopherdehaan.me)

---

## Repository Layout

```
CDMarkdownKit/
├── Source/                    # All library source files (the package target)
├── Tests/                     # SPM test target (189 tests across 31 suites)
├── Example/                   # iOS demo app
│   ├── Source/                # Example view controllers
│   └── Resources/             # Storyboards, assets, plist
├── Documentation/             # ARCHITECTURE.md, Usage.md, migration guide, images
├── docs/                      # DocC-generated HTML docs (served via GitHub Pages)
├── .github/
│   ├── workflows/ci.yml       # GitHub Actions CI
│   ├── ISSUE_TEMPLATE/        # bug_report.md, feature_request.md, config.yml
│   ├── FUNDING.yml            # GitHub Sponsors (chrisdhaan)
│   └── PULL_REQUEST_TEMPLATE.md
├── CDMarkdownKit.xcodeproj    # Xcode project (5 schemes: iOS, macOS, tvOS, watchOS, visionOS)
├── CDMarkdownKit.xcworkspace
├── Package.swift              # SPM manifest (swift-tools 6.0, swiftLanguageModes: [.v6])
├── CDMarkdownKit.podspec      # CocoaPods spec
├── .swiftlint.yml             # SwiftLint config (lints Source/ and Example/Source/)
├── Gemfile / Gemfile.lock     # cocoapods gem
├── scripts/generate-docs.sh  # Regenerates docs/ and adds GitHub Pages support files
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

---

## Platform & Swift Support

| Platform | `Package.swift` | Podspec |
|----------|----------------|---------|
| iOS      | 12.0+          | 12.0+   |
| macOS    | 10.13+         | 10.13+  |
| tvOS     | 12.0+          | 12.0+   |
| watchOS  | 4.0+           | 4.0+    |
| visionOS | 1.0+           | 1.0+    |

Swift minimum: **5.3** (enforced in `CDMarkdownKit.swift` via `#error`). The SPM manifest uses swift-tools-version 6.0 with `swiftLanguageModes: [.v6]` — compiled in Swift 6 language mode.

---

## Architecture

See `Documentation/ARCHITECTURE.md` for the full diagram. Summary:

**Three-phase parsing pipeline** inside `CDMarkdownParser.parse(_:)` (async):

```
Input String
    ↓
[Phase 1 — Escaping]
    CDMarkdownCodeEscaping   — UTF16-hex-encodes content inside backtick spans
    CDMarkdownEscaping       — UTF16-hex-encodes \-escaped characters

    ↓
[Phase 1.5 — Reference Definition Extraction]
    CDMarkdownLinkReference  — strips [ref]: url lines; populates references dict

    ↓
[Phase 2 — Element Parsing]  (order matters; earlier elements take priority)
    CDMarkdownTable          — pipe-delimited GFM tables
    CDMarkdownHorizontalRule — --- / *** / ___ dividers
    CDMarkdownHeader         — # H1 through ###### H6
    CDMarkdownTaskList       — - [x] / - [ ] items
    CDMarkdownList           — * / - / + list items (nested)
    CDMarkdownOrderedList    — 1. / 2. numbered items
    CDMarkdownQuote          — > blockquotes (nested)
    CDMarkdownLink           — [text](url)
    CDMarkdownAutomaticLink  — bare URLs via NSDataDetector
    CDMarkdownLinkReference  — [text][ref] resolved references
    CDMarkdownImage          — ![alt](url)   (iOS/macOS/tvOS only)
    CDMarkdownBold           — **text** or __text__
    CDMarkdownItalic         — *text* or _text_
    CDMarkdownStrikethrough  — ~~text~~
    [customElements]         — caller-provided CDMarkdownElement instances

    ↓
[Phase 3 — Unescaping]
    CDMarkdownCode           — `inline code`  (decodes UTF16-hex, strips \n)
    CDMarkdownSyntax         — ```fenced block``` (decodes UTF16-hex, handles bg wrapping)
    CDMarkdownUnescaping     — decodes all remaining UTF16-hex back to characters

    ↓
[Async image resolution]
    resolveImages(in:)       — downloads remote images via URLSession, injects NSTextAttachment
```

**Why escaping first?** Code spans must not be parsed for inner markdown. The escaping phase converts their contents to hex sequences that no other element regex can match, then Phase 3 reverses this.

---

## Protocol Hierarchy

```
CDMarkdownElement          (parse loop + regex matching)
├── CDMarkdownCommonElement + CDMarkdownStyle
│   ├── CDMarkdownBold
│   ├── CDMarkdownItalic
│   ├── CDMarkdownCode           (overrides addAttributes to unescape + strip \n)
│   ├── CDMarkdownSyntax         (overrides addAttributes; manages bg wrapping at \n)
│   └── CDMarkdownStrikethrough  (adds strikethrough attrs beyond CDMarkdownStyle)
├── CDMarkdownLevelElement  + CDMarkdownStyle  (block elements with nesting depth)
│   ├── CDMarkdownHeader         (font scales by heading level)
│   ├── CDMarkdownList           (replaces marker with bullet; handles head indent)
│   ├── CDMarkdownOrderedList    (replaces N. marker; tracks item numbering)
│   ├── CDMarkdownTaskList       (replaces - [x]/- [ ] with ✓/☐)
│   └── CDMarkdownQuote          (replaces > with indicator string)
├── CDMarkdownLinkElement   + CDMarkdownStyle
│   ├── CDMarkdownLink           (builds NSAttributedString .link attribute)
│   ├── CDMarkdownAutomaticLink  (extends CDMarkdownLink; uses NSDataDetector)
│   ├── CDMarkdownLinkReference  (resolves [text][ref] against references dict)
│   └── CDMarkdownImage          (placeholder image at parse time; async resolution in parser)
└── Direct CDMarkdownElement implementations
    ├── CDMarkdownTable          (pipe-delimited GFM tables)
    ├── CDMarkdownHorizontalRule (---, ***, ___ rules)
    ├── CDMarkdownCodeEscaping   (Phase 1 UTF16-hex encoding)
    ├── CDMarkdownEscaping       (Phase 1 backslash encoding)
    └── CDMarkdownUnescaping     (Phase 3 decode)
```

---

## Source File Map

### Core
| File | Purpose |
|------|---------|
| `CDMarkdownKit.swift` | Version constant; enforces Swift ≥ 5.3 |
| `CDMarkdownParser.swift` | `@MainActor` open class; orchestrates the 3-phase pipeline; `parse(_:)` is async |
| `CDMarkdownElement.swift` | Base `CDMarkdownElement` protocol + default `parse()` loop |
| `CDMarkdownStyle.swift` | `CDMarkdownStyle` protocol; builds `attributes` dict |
| `CDMarkdownCommonElement.swift` | `CDMarkdownCommonElement` protocol; `match()` strips delimiters |
| `CDMarkdownLevelElement.swift` | `CDMarkdownLevelElement` protocol; `match()` handles depth |
| `CDMarkdownLinkElement.swift` | `CDMarkdownLinkElement` protocol; `formatText` + `addAttributes` |

### Markdown Elements
| File | Element | Syntax |
|------|---------|--------|
| `CDMarkdownBold.swift` | Bold | `**text**` or `__text__` |
| `CDMarkdownItalic.swift` | Italic | `*text*` or `_text_` |
| `CDMarkdownHeader.swift` | Header | `# H1` – `###### H6` |
| `CDMarkdownList.swift` | List | `* / - / +` items |
| `CDMarkdownOrderedList.swift` | Ordered List | `1. / 2.` items |
| `CDMarkdownTaskList.swift` | Task List | `- [x]` / `- [ ]` items |
| `CDMarkdownQuote.swift` | Quote | `> text` |
| `CDMarkdownTable.swift` | Table | pipe-delimited rows |
| `CDMarkdownHorizontalRule.swift` | Horizontal Rule | `---` / `***` / `___` |
| `CDMarkdownLink.swift` | Link | `[text](url)` |
| `CDMarkdownAutomaticLink.swift` | AutoLink | bare URLs |
| `CDMarkdownLinkReference.swift` | Reference Link | `[text][ref]` + `[ref]: url` |
| `CDMarkdownImage.swift` | Image | `![alt](url)` — iOS/macOS/tvOS |
| `CDMarkdownCode.swift` | Inline code | `` `code` `` |
| `CDMarkdownSyntax.swift` | Fenced code | ` ```block``` ` |
| `CDMarkdownStrikethrough.swift` | Strikethrough | `~~text~~` |
| `CDMarkdownCodeEscaping.swift` | Escaping pass | internal |
| `CDMarkdownEscaping.swift` | Backslash escaping | internal |
| `CDMarkdownUnescaping.swift` | Unescape pass | internal |

### UI Components
| File | Platform | Purpose |
|------|----------|---------|
| `CDMarkdownLabel.swift` | iOS/tvOS | `@MainActor UILabel` subclass with custom text stack and tap-to-open-URL |
| `CDMarkdownTextView.swift` | iOS/tvOS | `@MainActor UITextView` subclass using `CDMarkdownLayoutManager` |
| `CDMarkdownLayoutManager.swift` | iOS/tvOS | `NSLayoutManager` subclass that draws rounded-corner backgrounds |
| `CDMarkdownNSTextView.swift` | macOS | `NSTextView` subclass for read-only markdown display |
| `CDMarkdownNSLabel.swift` | macOS | Lightweight read-only `NSView` for simple markdown display |
| `CDMarkdownNSLayoutManager.swift` | macOS | `NSLayoutManager` subclass with rounded-corner backgrounds |
| `CDMarkdownText.swift` | all (SwiftUI) | Lightweight SwiftUI `Text`-backed markdown view |
| `CDMarkdownView.swift` | iOS/tvOS/visionOS/macOS (SwiftUI) | Full-fidelity SwiftUI view with rounded corners and link handling |
| `CDMarkdownEnvironmentKey.swift` | all (SwiftUI) | `.markdownParser(_:)` and `.markdownTheme(_:)` environment modifiers |

### Theming
| File | Purpose |
|------|---------|
| `CDMarkdownTheme.swift` | `CDMarkdownTheme` value type; bundles styling for all elements; built-in `default` and `systemDark` themes |

### Cross-Platform Abstractions
| File | Exposes |
|------|---------|
| `CDFont.swift` | `CDFont` = `UIFont` / `NSFont` |
| `CDFont+CDMarkdownKit.swift` | `bold()`, `italic()`, `withSize()` on `CDFont` |
| `CDColor.swift` | `CDColor` = `UIColor` / `NSColor` |
| `CDColor+CDMarkdownKit.swift` | Theme colors (`codeTextRed`, `syntaxBackgroundGray`, etc.) |
| `CDImage.swift` | `CDImage` = `UIImage` / `NSImage` |
| `CDImage+CDMarkdownKit.swift` | Empty macOS extension (placeholder) |
| `CDAttributedStringKey.swift` | `CDAttributedStringKey` = `NSAttributedString.Key` |

### Extensions
| File | Extends | Adds |
|------|---------|------|
| `Dictionary+CDMarkdownKit.swift` | `Dictionary<CDAttributedStringKey, _>` | `addFont`, `addForegroundColor`, `addBackgroundColor`, `addParagraphStyle`, `addStrikethroughColor/Style`, `addUnderlineColor/Style` |
| `NSAttributedString+CDMarkdownKit.swift` | `NSAttributedString` | `enumerateLinkAttribute` |
| `NSMutableAttributedString+CDMarkdownKit.swift` | `NSMutableAttributedString` | `addFont`, `addForegroundColor`, `addBackgroundColor`, `addParagraphStyle`, `addLink`, `removeBackgroundColor` |
| `NSTextCheckingResult+CDMarkdownKit.swift` | `NSTextCheckingResult` | `nsRange(atIndex:)` |
| `NSTextStorage+CDMarkdownKit.swift` | `NSTextStorage` (iOS/tvOS) | `linkAttribute(at:effectiveRange:)` |
| `String+CDMarkdownKit.swift` | `String` | `escapeUTF16()`, `unescapeUTF16()`, `range(from:)`, `characterCount()`, `sizeWithAttributes()` |

---

## Distribution

Three supported distribution methods:

1. **Swift Package Manager** — primary, preferred going forward
2. **CocoaPods** — `CDMarkdownKit.podspec`; `pod lib lint` runs in CI
3. **Carthage** — README mentions it; no Cartfile in repo; largely deprecated

---

## CI / GitHub Actions

Defined in `.github/workflows/ci.yml`. Triggered on push to `master` and on pull requests when `Source/`, `Tests/`, `Package.swift`, or `.github/workflows/` change. All jobs use `fail-fast: false` and `timeout-minutes: 10–20`.

| Job | Strategy | Runner(s) | Tool |
|-----|----------|-----------|------|
| iOS | matrix: Xcode 26.1.1–26.4.1 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| macOS | matrix: Xcode 26.0.1–26.4.1 (macos-26) / Xcode 16.0–16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| tvOS | matrix: Xcode 26.1.1–26.4.1 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| watchOS | matrix: Xcode 26.1.1–26.4.1 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| visionOS | matrix: Xcode 26.1.1–26.4.1 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| Catalyst | single | macos-15, Xcode 16.4 | xcodebuild |
| CocoaPods | single | macos-15, Xcode 16.4 | pod lib lint |
| SPM | single | macos-15, Xcode 16.4 | swift test |
| SwiftLint | single | macos-15 | swiftlint --strict |
| SwiftFormat | single | macos-15 | swiftformat --lint |
| Documentation | single | macos-15, Xcode 16.4 | swift-docc-plugin |
| CodeQL | single | macos-15, Xcode 16.4 | codeql-action |

iOS/tvOS/watchOS/visionOS jobs run 5 matrix entries each (4 Xcode 26.x on macos-26, 1 Xcode 16.4 on macos-15), both Debug and Release builds. macOS/Catalyst/CocoaPods/SPM/SwiftLint/SwiftFormat/Documentation/CodeQL jobs run singles. All jobs use `actions/checkout@v4`, `xcbeautify --renderer github-actions`, and `set -o pipefail`.

---

## Known Issues & Tech Debt

### Medium Priority
1. **Swift 6 strict concurrency not fully adopted** — the package builds with `swiftLanguageModes: [.v6]` but some types use `@unchecked Sendable` and `@preconcurrency` conformances. A full strict-concurrency audit has not been completed.

### Low Priority / Future
2. **`CDMarkdownStrikethrough`** has its own `strikethroughColor`/`strikethroughStyle` properties that are not part of the shared `CDMarkdownStyle` protocol, creating an inconsistency.
3. **Carthage support** — README mentions Carthage compatibility but there is no `Cartfile`; Carthage is largely abandoned by the community.
4. **TextKit 2 migration** — `CDMarkdownLayoutManager` is an `NSLayoutManager` subclass, which forces `CDMarkdownTextView` into TextKit 1 compatibility mode (expected one-time console warning). A future v4.0 migration to `NSTextLayoutManager` would eliminate this. See `Documentation/ARCHITECTURE.md` for the current TK1 wiring approach.

---

## How to Build

```bash
# SPM build (no Xcode required)
swift build

# SPM build with specific configuration
swift build -c release

# Run tests
swift test

# Xcode (requires Xcode installed)
xcodebuild -project CDMarkdownKit.xcodeproj \
           -scheme "CDMarkdownKit iOS" \
           -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
           -configuration Debug \
           clean build
```

---

## How to Format

CDMarkdownKit uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for automated code formatting. Configuration is in `.swiftformat` at the repository root.

```bash
# Preview changes without writing files
swiftformat Source Tests --dryrun

# Apply formatting
swiftformat Source Tests

# CI mode: exit non-zero if any file would change
swiftformat Source Tests --lint
```

Run `swiftformat Source Tests` before committing new or modified source files to keep CI green.

---

## How to Generate Documentation

Uses the `swift-docc-plugin`. Always run via the wrapper script — it regenerates `docs/` and then adds `docs/.nojekyll` and `docs/404.html`, which DocC itself does not produce but GitHub Pages requires.

```bash
./scripts/generate-docs.sh
```

Output goes to `docs/`. The site is served from that directory via GitHub Pages at `https://chrisdhaan.github.io/CDMarkdownKit/`.

Do **not** run `swift package generate-documentation` directly to publish docs — it will wipe `.nojekyll` and `404.html`, breaking the live site.

---

## How to Add a New Markdown Element

1. Create `Source/CDMarkdownMyElement.swift`
2. Conform to one of `CDMarkdownCommonElement`, `CDMarkdownLevelElement`, or `CDMarkdownLinkElement`
3. Provide a `regex` string — test it with at least one positive and one negative case
4. Implement `match(_:attributedString:)` if the default isn't sufficient
5. Either register it as a `customElement` on `CDMarkdownParser`, or add it to `defaultElements` in `CDMarkdownParser.init`

---

## Version History Snapshot

| Version | Date       | Notable Change |
|---------|------------|----------------|
| 3.3.0   | 2026-06-03 | Reference-style links, fenced code language hints, `CDMarkdownTheme`, theme environment key |
| 3.2.0   | 2026-05-31 | Swift 6 language mode (`swiftLanguageModes: [.v6]`), task lists, horizontal rules, inline table cells, macOS AppKit components, SwiftUI wrappers |
| 3.1.0   | 2026-05-12 | Tables, ordered lists, visionOS support, DocC documentation |
| 3.0.0   | 2026-05-09 | Async parse, Swift 6 toolchain, unified Package.swift, Jazzy docs, modern CI |
| 2.5.1   | 2022-12-13 | Swift 5.7 support |
| 2.5.0   | 2022-12-12 | Underline color/style on all elements |
| 2.4.0   | 2022-12-03 | Strikethrough element |
| 2.3.0   | 2022-10-17 | `squashNewlines` parameter |
| 2.2.0   | 2022-06-26 | Swift 5.4/5.5/5.6; minimum SPM Swift 5.3 |
| 2.1.1   | 2021-05-29 | Bold/italic parsing fix |
| 2.0.0   | 2020-08-29 | Swift 5.0 |
| 1.0.0   | 2018-06-11 | Initial public release |
