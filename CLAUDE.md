# CDMarkdownKit — Claude Guide

## Project Overview

CDMarkdownKit is a pure-Swift, zero-dependency framework for parsing Markdown text into `NSAttributedString`. It supports rendering inside custom `UILabel` and `UITextView` subclasses with optional rounded-corner background styling for code and syntax blocks.

- **Current version**: 4.1.0
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
| iOS      | 13.0+          | 13.0+   |
| macOS    | 10.15+         | 10.15+  |
| tvOS     | 13.0+          | 13.0+   |
| watchOS  | 6.0+           | 6.0+    |
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
    CDMarkdownImage          — ![alt](url)   (iOS/macOS/tvOS/visionOS only)
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
│   └── CDMarkdownStrikethrough  (sets strikethroughColor/strikethroughStyle)
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
| `CDMarkdownImage.swift` | Image | `![alt](url)` — iOS/macOS/tvOS/visionOS |
| `CDMarkdownCode.swift` | Inline code | `` `code` `` |
| `CDMarkdownSyntax.swift` | Fenced code | ` ```block``` ` |
| `CDMarkdownStrikethrough.swift` | Strikethrough | `~~text~~` |
| `CDMarkdownCodeEscaping.swift` | Escaping pass | internal |
| `CDMarkdownEscaping.swift` | Backslash escaping | internal |
| `CDMarkdownUnescaping.swift` | Unescape pass | internal |

### UI Components
| File | Platform | Purpose |
|------|----------|---------|
| `CDMarkdownLabel.swift` | iOS/tvOS/visionOS | `@MainActor UILabel` subclass with custom text stack and tap-to-open-URL |
| `CDMarkdownTextView.swift` | iOS/tvOS/visionOS | `@MainActor UITextView` subclass; on iOS/tvOS 16+ assigns a `CDMarkdownTextLayoutDelegate` to the stock `NSTextLayoutManager` (TextKit 2), falls back to `CDMarkdownLayoutManager` (TextKit 1) on iOS/tvOS 15 |
| `CDMarkdownTextLayoutManager.swift` | iOS/tvOS/visionOS | Defines `CDMarkdownTextLayoutDelegate`, an `NSTextLayoutManagerDelegate` (TextKit 2) that supplies `CDMarkdownTextLayoutFragment` instances for rounded-corner background drawing |
| `CDMarkdownTextLayoutFragment.swift` | iOS/tvOS/visionOS | `NSTextLayoutFragment` subclass (TextKit 2) that draws rounded-corner backgrounds |
| `CDMarkdownLayoutManager.swift` | iOS/tvOS/visionOS | `NSLayoutManager` subclass (TextKit 1 fallback) that draws rounded-corner backgrounds |
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

Two supported distribution methods:

1. **Swift Package Manager** — primary, preferred going forward
2. **CocoaPods** — `CDMarkdownKit.podspec`; `pod lib lint` runs in CI

### Publishing to CocoaPods

`pod trunk push` requires `--allow-warnings` because the trunk server's validator does not yet recognise the `visionos` platform key, even though local `pod lib lint` passes clean:

```bash
pod trunk push CDMarkdownKit.podspec --allow-warnings
```

---

## CI / GitHub Actions

Defined in `.github/workflows/ci.yml`. Triggered on push to `master` and on pull requests when `Source/`, `Tests/`, `Package.swift`, or `.github/workflows/` change. All jobs use `fail-fast: false` and `timeout-minutes: 10–20`.

| Job | Strategy | Runner(s) | Tool |
|-----|----------|-----------|------|
| iOS | matrix: Xcode 26.2–26.5 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| macOS | matrix: Xcode 26.0.1–26.5 (macos-26) / Xcode 16.0–16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| tvOS | matrix: Xcode 26.2–26.5 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| watchOS | matrix: Xcode 26.2–26.5 (macos-26) / Xcode 16.4 (macos-15) | macos-26 / macos-15 | xcodebuild |
| visionOS | matrix: Xcode 26.2–26.5 (macos-26) | macos-26 | xcodebuild |
| UITests | single, per-platform (iOS/tvOS/visionOS) | macos-26, Xcode 26.5 | xcodebuild test |
| Catalyst | single | macos-15, Xcode 16.4 | xcodebuild |
| CocoaPods | single | macos-15, Xcode 16.4 | pod lib lint |
| SPM | single | macos-15, Xcode 16.4 | swift test |
| SwiftLint | single | macos-15 | swiftlint --strict |
| SwiftFormat | single | macos-15 | swiftformat --lint |
| Documentation | single | macos-15, Xcode 16.4 | swift-docc-plugin |
| CodeQL | single | macos-15, Xcode 16.4 | codeql-action |

iOS/tvOS/watchOS jobs run 5 matrix entries each (4 Xcode 26.x on macos-26, 1 Xcode 16.4 on macos-15), both Debug and Release builds. visionOS runs 4 entries (macos-26 only), both Debug and Release. macOS/Catalyst/CocoaPods/SPM/SwiftLint/SwiftFormat/Documentation/CodeQL jobs run singles. All jobs use `actions/checkout@v4`, `xcbeautify --renderer github-actions`, and `set -o pipefail`.

`UITests` actually executes the iOS/tvOS/visionOS-gated test suite (`Tests/CDMarkdownKitTests/UI/` and friends) against a real simulator, one platform per matrix entry — see "Running iOS/tvOS/visionOS-gated tests locally" below for why it stages a bare copy of `Source/`/`Tests/`/`Package.swift` rather than using `CDMarkdownKit.xcodeproj` directly. watchOS has no UI-gated components (see the UI Components table above) so it's excluded from this job's matrix.

### Debugging CI Destination Failures

When an `xcodebuild` destination specifier fails (simulator not found, no matching device), check the runner's installed simulators at:

**https://github.com/actions/runner-images** → `images/macos/macos-26-arm64-Readme.md` → "Installed Simulators" table

The **OS** column in that table gives the exact version string required for the `OS=` parameter in xcodebuild destination specifiers. Key gotchas:

- **iOS/visionOS point releases**: the iOS 26.4 and visionOS 26.4 simulators have OS `26.4.1` (not `26.4`) — tvOS and watchOS 26.4 stay at `26.4`

---

## Known Issues & Tech Debt

### Waiting on Apple dropping iOS 15

These are intentionally deferred until Apple stops supporting iOS 15 (i.e., a future Xcode drops it as a deployment target). Do not raise them before then.

1. **Remove TextKit 1 fallback** — `CDMarkdownLayoutManager` and the `configureTK1()` path in `CDMarkdownLabel`/`CDMarkdownTextView` can be deleted once iOS 15 is no longer a supported target.
2. **`CDMarkdownTheme: @unchecked Sendable`** — `NSFont` and `NSParagraphStyle` are not `Sendable` below iOS 16; full Swift 6 strict concurrency for the theme requires the same deployment floor bump.

### Low Priority / Future
3. **Carthage** — removed as of 3.0.0 (see `Documentation/CDMarkdownKit 3.0 Migration Guide.md`). Not mentioned in README or current Usage.md; no further action needed.

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

### Running iOS/tvOS/visionOS-gated tests locally

`swift test` only runs on the macOS host, where every file under `#if os(iOS) || os(tvOS) || os(visionOS)` compiles to nothing — it cannot execute or even compile-check UIKit-gated tests (e.g. everything in `Tests/CDMarkdownKitTests/UI/`). `xcodebuild -project CDMarkdownKit.xcodeproj` doesn't help either: none of its 5 schemes have `CDMarkdownKitTests` wired into their Testables, and `xcodebuild -list` run from the repo root never shows an SPM package scheme, because the `.xcodeproj`'s presence shadows it.

There is a working command-line path today, discovered while building out TextKit 2 test coverage: copy just the SPM package files into a directory that does **not** contain `CDMarkdownKit.xcodeproj`, so `xcodebuild` falls back to the package's own auto-generated scheme:

```bash
# From the repo root:
SCRATCH=$(mktemp -d)
cp -R Source Tests Package.swift Package.resolved "$SCRATCH"/
cd "$SCRATCH"

xcodebuild -list   # confirm "CDMarkdownKit-Package" now appears under Schemes

xcodebuild test -scheme CDMarkdownKit-Package \
                -destination "platform=iOS Simulator,name=iPhone 17 Pro"

rm -rf "$SCRATCH"
```

This actually compiles and runs the full suite (Swift Testing + XCTest) against a real simulator — not just a typecheck. It's how a handful of real production bugs (`configureTK2()` never configuring TextKit 2, `urlRangeTK1(at:)` missing a coordinate-space offset, a `CDMarkdownTextView` initializer crash) were actually caught: none of them were visible to `swift build`, `swift test`, or `xcodebuild clean build`, only to a real test run. This is now automated as CI's `UITests` job (see the CI table above). Wiring `CDMarkdownKitTests` into the checked-in `.xcodeproj` schemes' native Testables directly (rather than working around the `.xcodeproj`'s presence) remains an open item — it needs the Xcode GUI, since hand-editing `project.pbxproj`'s Swift package product references for a test-only target isn't reliably reproducible via script (confirmed: `xcodebuild` reports "Missing package product" even when the object graph looks correct).

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
| 4.1.0   | 2026-08-03 | Leading-whitespace handling now dedents instead of stripping every line outright, fixing indentation-based nested unordered lists under default settings; fixed indented blockquote/ordered-list parsing regressions from that change; `CDMarkdownTable` column-width and `CDMarkdownLabel` TK2 fixes; `CDMarkdownView`/`CDMarkdownText` test coverage |
| 4.0.3   | 2026-07-31 | Fixed `CDMarkdownLabel` never rendering on iOS/tvOS 16+ (TextKit 2 setup always failed); fixed TextKit 1 link-tap hit-testing; added TextKit 2 test coverage |
| 4.0.2   | 2026-07-24 | Monthly review bug-fix pass: parsing (URL parens, emoji code spans, CRLF), UI rendering (TextKit 1/2, nil crash), doc accuracy |
| 4.0.1   | 2026-06-15 | Fix infinite recursion in `CDColor.label` on iOS/tvOS/watchOS/visionOS |
| 4.0.0   | 2026-06-15 | TextKit 2 migration (iOS/tvOS 16+), raised deployment targets, Swift 6 strict concurrency |
| 3.3.0   | 2026-06-03 | Reference-style links, fenced code language hints, `CDMarkdownTheme`, theme environment key |
| 3.2.0   | 2026-05-31 | Swift 6 language mode (`swiftLanguageModes: [.v6]`), task lists, horizontal rules, inline table cells, macOS AppKit components, SwiftUI wrappers |
| 3.1.0   | 2026-05-12 | Tables, ordered lists, visionOS support, DocC documentation |
| 3.0.0   | 2026-05-10 | Async parse, Swift 6 toolchain, unified Package.swift, Jazzy docs, modern CI |
| 2.5.1   | 2022-12-13 | Swift 5.7 support |
| 2.5.0   | 2022-12-12 | Underline color/style on all elements |
| 2.4.0   | 2022-12-03 | Strikethrough element |
| 2.3.0   | 2022-10-17 | `squashNewlines` parameter |
| 2.2.0   | 2022-06-26 | Swift 5.4/5.5/5.6; minimum SPM Swift 5.3 |
| 2.1.1   | 2021-05-29 | Bold/italic parsing fix |
| 2.0.0   | 2020-08-29 | Swift 5.0 |
| 1.0.0   | 2018-06-11 | Initial public release |
