# CDMarkdownKit — Modernization Implementation Plan

> Implementation plan for bringing CDMarkdownKit from v2.5.1 (released 2022-12-13) to a current, well-maintained open source Swift package. Informed by `CLAUDE.md`, `ARCHITECTURE.md`, and `Alamofire.md`.
>
> Each section is self-contained and can be implemented independently. Complete sections 1–4 before starting section 6 (tests). Complete section 3 before starting section 7 (concurrency). Section 8 depends on section 7.

---

## 1. Repository Housekeeping

Quick, low-risk changes that improve the repo's credibility and contributor experience before any code changes are made.

### Steps

**1.1 — Reformat `CHANGELOG.md`** ✅

Open `CHANGELOG.md`. Replace the existing content structure with the following format. Keep all existing release entries but reformat them to match:

```markdown
# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

## Table of Contents

- [3.0.0](#300)
- [2.5.1](#251)
- [2.5.0](#250)
- ... (one line per release, linking to the anchor below)

---

## [3.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/3.0.0)

Released on YYYY-MM-DD.

### Added
- Description.
  - Added by [Christopher de Haan](https://github.com/cdehaan) in Pull Request [#NNN](link).

### Updated
- Description.
  - Updated by [Christopher de Haan](https://github.com/cdehaan) in Pull Request [#NNN](link).

### Fixed
- Description.
  - Fixed by [Christopher de Haan](https://github.com/cdehaan) in Pull Request [#NNN](link).

---

## [2.5.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.5.1)

Released on 2022-12-13.

### Added
- (existing entry text, reformatted)
```

Rules:
- Dates in `YYYY-MM-DD` format.
- Three categories only: **Added**, **Updated**, **Fixed**. No others.
- Each bullet ends with attribution: `Added by [Name](profile link) in Pull Request [#NNN](PR link).`
- If an old entry has no PR link, omit the attribution line entirely rather than leaving a broken link.
- Releases separated by `---`.

**1.2 — Replace the single issue template with a directory** ✅

Delete `.github/ISSUE_TEMPLATE.md`.

Create `.github/ISSUE_TEMPLATE/config.yml`:
```yaml
blank_issues_enabled: false
contact_links:
  - name: Usage Question
    url: https://stackoverflow.com/questions/tagged/cdmarkdownkit
    about: Please ask usage questions on Stack Overflow using the `cdmarkdownkit` tag.
  - name: Security Vulnerability
    url: mailto:contact@christopherdehaan.me
    about: Please report security vulnerabilities privately via email.
```

Create `.github/ISSUE_TEMPLATE/bug_report.md`:
```markdown
---
name: Bug Report
about: Report a reproducible bug or regression.
labels: bug
---

**What did you do?**
<!-- A clear description of the steps that produced the bug. -->

**What did you expect to happen?**

**What actually happened?**

**CDMarkdownKit version:**

**Swift version:**

**Platform and OS version:**

**Minimal reproducible example:**
<!-- A short Swift snippet or Markdown input string that demonstrates the bug. -->
```

Create `.github/ISSUE_TEMPLATE/feature_request.md`:
```markdown
---
name: Feature Request
about: Suggest a new feature or enhancement.
labels: enhancement
---

**What problem does this feature solve?**

**Describe the solution you'd like.**

**Have you considered any alternatives?**
```

**1.3 — Update the PR template** ✅

Replace the contents of `.github/PULL_REQUEST_TEMPLATE.md` with:

```markdown
### Issue

> Link to the GitHub issue this PR addresses.

### Goals

> Bullet list of what this PR accomplishes.

### Implementation Details

> Describe any non-obvious implementation decisions.

### Testing Details

> How was this tested? List new tests added, or explain why no tests are needed.
```

**1.4 — Add `FUNDING.yml`** ✅

Create `.github/FUNDING.yml`:
```yaml
github: chrisdhaan
```

**1.5 — Add `Gemfile`** ✅

Create `Gemfile` at the repo root:
```ruby
source "https://rubygems.org"

gem "cocoapods"
gem "jazzy"
```

Run `bundle install` from the repo root to generate `Gemfile.lock`. Commit both `Gemfile` and `Gemfile.lock`.

---

## 2. CI / GitHub Actions

Updates to `.github/workflows/ci.yml` only. No source code changes.

The current CI only builds; it does not run tests. The jobs below are structured to also run tests once the `Tests/` target exists (section 6). Until then, replace `clean test` with `clean build` and `swift test` with `swift build` in any job that would fail without a test target.

### Steps

**2.1 — Add a top-level concurrency block** ✅

Add the following immediately after the `on:` block (before `jobs:`):

```yaml
concurrency:
  group: ${{ github.ref_name }}
  cancel-in-progress: true
```

**2.2 — Update `actions/checkout` to `@v4`** ✅

In every job's `steps:`, replace:
```yaml
- uses: actions/checkout@v3
```
with:
```yaml
- uses: actions/checkout@v4
```

**2.3 — Update all macOS runners and Xcode versions** ✅

Replace every instance of:
- `macos-12` → `macos-15`
- `macos-11` → `macos-15`
- `macos-10.15` → `macos-15`
- `Xcode_14.1.app` → `Xcode_16.2.app`
- `Xcode_14.app` → `Xcode_16.2.app`
- Any other `Xcode_XX.app` reference → `Xcode_16.2.app`

After any job that references Xcode, add this step before the build step to select the correct version:
```yaml
- name: Select Xcode
  run: sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
```

**2.4 — Add `timeout-minutes` and `fail-fast: false` to every job** ✅

For every job that has a `strategy: matrix:` block, add directly under `strategy:`:
```yaml
    fail-fast: false
```

For every job (matrix or not), add at the job level:
```yaml
    timeout-minutes: 10
```

**2.5 — Add `xcbeautify` installation and pipe all `xcodebuild` output through it** ✅

In every job that runs `xcodebuild`, add a setup step before the build step:
```yaml
- name: Install xcbeautify
  run: brew install xcbeautify
```

Then update every `xcodebuild` command from this pattern:
```bash
xcodebuild -project CDMarkdownKit.xcodeproj \
  -scheme "CDMarkdownKit iOS" \
  -destination "..." \
  -configuration Debug \
  clean build
```
to this pattern:
```bash
set -o pipefail
env NSUnbufferedIO=YES xcodebuild \
  -project CDMarkdownKit.xcodeproj \
  -scheme "CDMarkdownKit iOS" \
  -destination "..." \
  -configuration Debug \
  clean build 2>&1 | xcbeautify --renderer github-actions
```

**2.6 — Update the path filters** ✅

In the `on: push: paths:` and `on: pull_request: paths:` blocks, add `Tests/**` alongside the existing `Source/**`:

```yaml
on:
  push:
    branches:
      - master
    paths:
      - .github/workflows/**
      - Package.swift
      - Source/**
      - Tests/**
  pull_request:
    paths:
      - .github/workflows/**
      - Package.swift
      - Source/**
      - Tests/**
```

**2.7 — Update the SPM job** ✅

Find the job that runs `swift build` (the SPM job). Update its command to:
```bash
set -o pipefail && swift build 2>&1 | xcbeautify --renderer github-actions
```

Once section 6 (unit tests) is complete, change `swift build` to `swift test -c debug`.

**2.8 — Add a SwiftLint enforcement job** ✅

Add a new job to `ci.yml`:

```yaml
  swiftlint:
    name: SwiftLint
    runs-on: macos-15
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - name: Install SwiftLint
        run: brew install swiftlint
      - name: Lint
        run: swiftlint lint --strict
```

**2.9 — Add a CodeQL security scanning job** ✅

Add a new job to `ci.yml`:

```yaml
  codeql:
    name: CodeQL
    runs-on: macos-15
    timeout-minutes: 20
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: swift
      - name: Build
        run: |
          xcodebuild -project CDMarkdownKit.xcodeproj \
            -scheme "CDMarkdownKit iOS" \
            -destination "generic/platform=iOS" \
            -configuration Debug \
            clean build
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
```

**2.10 — Remove the `pod lib lint` jobs (or update them)** ✅

The `pod lib lint` job requires CocoaPods to be installed and the Gemfile to be in place. Update the job to use `bundle exec pod lib lint` to use the pinned CocoaPods version from the Gemfile (completed in section 1.5):

```yaml
- name: Install Gems
  run: bundle install
- name: pod lib lint
  run: bundle exec pod lib lint --allow-warnings
```

---

## 3. Swift Package Manager

Changes to `Package.swift` and the versioned `Package@swift-X.Y.swift` manifests.

### Steps

**3.1 — Add `swiftLanguageModes: [.v5]` to `Package.swift`** ✅

Open `Package.swift`. Find the closing `)` of the `Package(...)` initializer. Add `swiftLanguageModes: [.v5]` as the last parameter before the closing `)`:

```swift
let package = Package(
    name: "CDMarkdownKit",
    // ... existing content ...
    swiftLanguageModes: [.v5]
)
```

**3.2 — Add a dynamic library product** ✅

In `Package.swift`, find the `products:` array. It currently has one entry. Add a second entry for the dynamic variant:

```swift
products: [
    .library(
        name: "CDMarkdownKit",
        targets: ["CDMarkdownKit"]),
    .library(
        name: "CDMarkdownKitDynamic",
        type: .dynamic,
        targets: ["CDMarkdownKit"]),
],
```

**3.3 — Create `Source/PrivacyInfo.xcprivacy`** ✅

Create `Source/PrivacyInfo.xcprivacy` with the following content. CDMarkdownKit does not collect data, does not track users, and does not use any APIs that require a reason string:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
</dict>
</plist>
```

**3.4 — Declare `PrivacyInfo.xcprivacy` as a resource in `Package.swift`** ✅

Find the `.target(name: "CDMarkdownKit", ...)` block in `Package.swift`. Add a `resources:` parameter:

```swift
.target(
    name: "CDMarkdownKit",
    path: "Source",
    resources: [.process("PrivacyInfo.xcprivacy")]
),
```

If there is an existing `exclude:` parameter listing `Info.plist` or other files, keep it and add `resources:` alongside it.

**3.5 — Update deployment targets** ✅

In `Package.swift`, update the `platforms:` array to the following minimums. These targets enable native Swift concurrency APIs (`async/await`) and are the recommended floor for a v3.0 release:

```swift
platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
],
```

Apply the same platform values to all versioned `Package@swift-X.Y.swift` files.

**3.6 — Review and consolidate versioned `Package@swift-X.Y.swift` files** ✅

Open each versioned manifest (`Package@swift-5.3.swift`, `Package@swift-5.4.swift`, `Package@swift-5.5.swift`, `Package@swift-5.6.swift`) and compare its content against the updated `Package.swift`. For each file:
- If the only difference is the `swift-tools-version` comment on line 1, delete the file — it is now redundant.
- If the file declares lower deployment targets for older toolchain compatibility that is still needed, keep it but update its content to otherwise match `Package.swift`.

The goal is to have no versioned files if possible, or the minimum number needed to support older toolchains your users realistically run.

**3.7 — Verify the build** ✅

Run `swift build` from the repo root. The build must succeed with no errors before moving on.

---

## 4. CocoaPods Podspec

Changes to `CDMarkdownKit.podspec` only.

### Steps

**4.1 — Update deployment targets** ✅

Update the platform declarations to match the SPM targets set in step 3.5:

```ruby
s.ios.deployment_target     = '15.0'
s.osx.deployment_target     = '12.0'
s.tvos.deployment_target    = '15.0'
s.watchos.deployment_target = '8.0'
```

**4.2 — Add `cocoapods_version` constraint** ✅

Add the following line near the top of the podspec (after `s.version`):

```ruby
s.cocoapods_version = '>= 1.13.0'
```

This is required for correct `PrivacyInfo.xcprivacy` resource bundling introduced in CocoaPods 1.13.

**4.3 — Add `resource_bundles` for the privacy manifest** ✅

Add the following line to the podspec:

```ruby
s.resource_bundles = { 'CDMarkdownKit' => ['Source/PrivacyInfo.xcprivacy'] }
```

**4.4 — Add `swift_versions`** ✅

Add or verify the following line exists:

```ruby
s.swift_versions = ['5']
```

**4.5 — Add `documentation_url` (placeholder)** ✅

Add the following line. Replace it with the real URL once GitHub Pages is enabled in section 9:

```ruby
s.documentation_url = 'https://chrisdhaan.github.io/CDMarkdownKit/'
```

**4.6 — Validate the podspec** ✅

Run `bundle exec pod lib lint --allow-warnings` from the repo root. The podspec must lint cleanly before moving on.

---

## 5. Bug Fixes

Three known bugs identified in the audit. Each is an isolated change to a single file.

### Bug 1 — `urlRanges` accumulates across `attributedText` assignments ✅

**File**: `Source/CDMarkdownLabel.swift`  
**Problem**: `parseTextAndExtractURLRanges(_:)` appends to `urlRanges` without ever clearing it. Setting `attributedText` multiple times on the same label accumulates URL ranges from all previous assignments, producing incorrect tap targets.

**Fix**: In `parseTextAndExtractURLRanges(_:)` (line ~333), add `urlRanges.removeAll()` as the very first line of the method body:

```swift
private func parseTextAndExtractURLRanges(_ attrString: NSAttributedString) {
    urlRanges.removeAll()   // ← add this line
    attrString.enumerateLinkAttribute(in: NSRange(location: 0,
                                                  length: attrString.length),
                                      options: [.longestEffectiveRangeNotRequired]) { value, range, _ in
        // ... existing code unchanged ...
    }
}
```

**Verify**: After the fix, confirm via a test (section 6) or manual inspection that calling the method twice produces only the ranges from the second call.

---

### Bug 2 — `CDMarkdownLayoutManager` hardcodes color comparison for corner rounding ✅

**File**: `Source/CDMarkdownLayoutManager.swift`  
**Problem**: `fillBackgroundRectArray` compares the incoming `color` parameter against `UIColor.codeBackgroundRed()` and `UIColor.syntaxBackgroundGray()` by RGBA value to decide whether to draw rounded corners. This breaks when the caller customizes those colors or when using dynamic/adaptive colors.

**Fix**: Replace the color comparison with a custom `NSAttributedString.Key` attribute that is written to the attributed string during parsing and read back in the layout manager at draw time.

**Step 1** — Add the custom key. In `Source/CDAttributedStringKey.swift` (or create a new file `Source/NSAttributedString.Key+CDMarkdownKit.swift`), add:

```swift
extension NSAttributedString.Key {
    static let cdMarkdownRoundedBackground = NSAttributedString.Key("CDMarkdownKit.roundedBackground")
}
```

**Step 2** — Write the attribute during parsing. In `Source/CDMarkdownCode.swift`, find the `addAttributes(_:range:)` method. After applying the existing attributes, add:

```swift
attributedString.addAttribute(.cdMarkdownRoundedBackground,
                               value: true as AnyObject,
                               range: range)
```

Do the same in `Source/CDMarkdownSyntax.swift` in its `addAttributes(_:range:)` override.

**Step 3** — Read the attribute in the layout manager. In `Source/CDMarkdownLayoutManager.swift`, replace the existing corner radius logic:

```swift
// BEFORE:
var cornerRadius: CGFloat = 0
if (self.roundCodeCorners == true && color.isEqualTo(otherColor: UIColor.codeBackgroundRed())) ||
    (self.roundSyntaxCorners == true && color.isEqualTo(otherColor: UIColor.syntaxBackgroundGray())) ||
    self.roundAllCorners == true {
    cornerRadius = 3
}
```

```swift
// AFTER:
var cornerRadius: CGFloat = 0
let hasRoundedAttribute = self.textStorage?.attribute(
    .cdMarkdownRoundedBackground,
    at: charRange.location,
    effectiveRange: nil) as? Bool == true
if hasRoundedAttribute || self.roundAllCorners {
    cornerRadius = 3
}
```

Remove the `roundCodeCorners` and `roundSyntaxCorners` properties from `CDMarkdownLayoutManager` since the new approach makes them redundant. Update any references to these properties in the Example app or README.

**Verify**: `swift build` succeeds. Color customization on `CDMarkdownCode` and `CDMarkdownSyntax` now correctly produces rounded corners regardless of the color value.

---

### Bug 3 — `CDMarkdownStrikethrough` properties are not part of `CDMarkdownStyle` ✅

**File**: `Source/CDMarkdownStyle.swift`, `Source/CDMarkdownStrikethrough.swift`  
**Problem**: `CDMarkdownStrikethrough` has `strikethroughColor` and `strikethroughStyle` properties that are not declared in `CDMarkdownStyle`, while all other style properties (`underlineColor`, `underlineStyle`, etc.) are. This creates an inconsistency: callers who hold a `CDMarkdownStyle` reference cannot access strikethrough styling.

**Fix**: Add the two properties to `CDMarkdownStyle`.

**Step 1** — In `Source/CDMarkdownStyle.swift`, add the two properties to the protocol declaration:

```swift
public protocol CDMarkdownStyle {
    var font: CDFont? { get }
    var color: CDColor? { get }
    var backgroundColor: CDColor? { get }
    var paragraphStyle: NSParagraphStyle? { get }
    var underlineColor: CDColor? { get }
    var underlineStyle: NSUnderlineStyle? { get }
    var strikethroughColor: CDColor? { get }   // ← add
    var strikethroughStyle: NSUnderlineStyle? { get }  // ← add
}
```

**Step 2** — In the same file, add default `nil` implementations in the protocol extension so existing conformers do not need to change:

```swift
public extension CDMarkdownStyle {
    var strikethroughColor: CDColor? { return nil }
    var strikethroughStyle: NSUnderlineStyle? { return nil }
}
```

**Step 3** — In the same file, update the `attributes` computed property in the extension to include strikethrough attributes when non-nil. Find where `underlineColor` and `underlineStyle` are applied and add the same pattern for strikethrough:

```swift
if let strikethroughColor = strikethroughColor {
    attributes.addStrikethroughColor(strikethroughColor)
}
if let strikethroughStyle = strikethroughStyle {
    attributes.addStrikethroughStyle(strikethroughStyle)
}
```

**Step 4** — In `Source/CDMarkdownStrikethrough.swift`, the `addAttributes(_:range:)` override can now be deleted entirely since the base `attributes` dict in `CDMarkdownStyle` already handles strikethrough. Verify that removing it does not change behavior by confirming `CDMarkdownStrikethrough` still applies strikethrough attributes via the inherited `addAttributes` from `CDMarkdownCommonElement`.

**Verify**: `swift build` succeeds. A `CDMarkdownStrikethrough` instance accessed as `CDMarkdownStyle` correctly exposes its strikethrough properties.

---

### Bug 4 — `CDMarkdownAutomaticLink` crashes on watchOS ✅

**File**: `Source/CDMarkdownAutomaticLink.swift`  
**Problem**: `regularExpression()` calls `NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)`. On older watchOS versions, `NSDataDetector` could throw an Objective-C `NSException` when initialized with the link type. Swift's `do-catch` does not catch ObjC exceptions, so the `parse()` loop's empty `catch {}` in `CDMarkdownElement.swift` does not protect against this crash. Additionally, link taps are not supported in `WKInterfaceLabel`, so automatic link detection provides no user-visible benefit on watchOS.

**Fix**: Override `regularExpression()` in `CDMarkdownAutomaticLink` to return a no-op regex on watchOS. This prevents the crash and avoids unnecessary work on a platform where the feature does nothing.

In `Source/CDMarkdownAutomaticLink.swift`, replace:

```swift
open override func regularExpression() throws -> NSRegularExpression {
    return try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
}
```

with:

```swift
open override func regularExpression() throws -> NSRegularExpression {
    #if os(watchOS)
    return try NSRegularExpression(pattern: "(?!)", options: [])
    #else
    return try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    #endif
}
```

`(?!)` is a regex that never matches, so the element silently produces no output on watchOS without crashing.

**Verify**: `swift build` succeeds. On watchOS builds, no crash occurs when `CDMarkdownParser` is initialized and `parse()` is called.

---

### Bug 5 — Link regex requires a preceding character; `[^!{1}]` incorrectly excludes extra characters ✅

**File**: `Source/CDMarkdownLink.swift`  
**Problem**: The regex on line 36 is:

```swift
fileprivate static let regex = "[^!{1}]\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"
```

This has two bugs:
1. `[^!{1}]` is a character class that excludes `!`, `{`, `1`, and `}` — not just `!` as intended. A character class does not support `{1}` quantifier syntax; the `{`, `1`, and `}` are treated as literal characters to exclude.
2. The leading `[^!{1}]` requires exactly one non-`!` character before `[`, which means a link at the very start of a string (position 0) is never matched.

**Fix — Step 1**: In `Source/CDMarkdownLink.swift`, replace the regex on line 36 with a negative lookbehind. A lookbehind is zero-width (consumes no characters), correctly handles position 0, and excludes only `!`:

```swift
fileprivate static let regex = "(?<![!])\\[([^\\[]*?)\\]\\(([^\\)]*)\\)"
```

**Fix — Step 2**: The `match(_:attributedString:)` method in the same file contains offsets that assumed the match started at the leading non-`!` character (i.e., one position before `[`). With the lookbehind, the match now starts directly at `[`. Update two locations in `match(_:attributedString:)`:

*Change 1* — the leading delimiter deletion (line ~101):

```swift
// BEFORE:
attributedString.deleteCharacters(in: NSRange(location: match.range.location + 1,
                                              length: 1))
```

```swift
// AFTER:
attributedString.deleteCharacters(in: NSRange(location: match.range.location,
                                              length: 1))
```

*Change 2* — the format range calculation (lines ~103–104):

```swift
// BEFORE:
let formatRange = NSRange(location: match.range.location + 1,
                          length: linkStartInResult - match.range.location - 3)
```

```swift
// AFTER:
let formatRange = NSRange(location: match.range.location,
                          length: linkStartInResult - match.range.location - 2)
```

The `- 3` becomes `- 2` because the match no longer includes the leading character, and the location no longer needs the `+ 1` shift. The math still correctly isolates the link display text between `[` and `]`.

**Verify**: `swift build` succeeds. `[Link](https://example.com)` at position 0 now produces a link. A `1[Link](url)` (previously excluded because `1` was in the character class) now also produces a link. `![img](url)` is still correctly excluded.

---

### Bug 6 — Force unwrap crash in `CDFont+CDMarkdownKit.swift` with custom fonts ✅

**File**: `Source/CDFont+CDMarkdownKit.swift`  
**Problem**: `withTraits(_:)` at lines 55–58 force-unwraps the result of `fontDescriptor.withSymbolicTraits(_:)`:

```swift
private func withTraits(_ traits: CDFontDescriptorSymbolicTraits...) -> CDFont {
    let descriptor = fontDescriptor.withSymbolicTraits(CDFontDescriptorSymbolicTraits(traits))
    return CDFont(descriptor: descriptor!,   // crash when descriptor is nil
                  size: self.pointSize)
}
```

`UIFontDescriptor.withSymbolicTraits(_:)` returns `nil` when the font does not support the requested trait — for example, a custom font that has no bold or italic variant. Any call to `markdownParser.bold.font = UIFont(name: "MyFont", size: 16)` where `"MyFont"` has no bold face will crash when CDMarkdownKit tries to apply bold styling.

**Fix**: Replace the force unwrap with a `guard let` that falls back to returning `self` (the original font, unchanged) when the trait is unavailable. This is the correct behavior — if a font has no bold variant, display it as-is rather than crashing.

In `Source/CDFont+CDMarkdownKit.swift`, replace lines 55–59:

```swift
// BEFORE:
private func withTraits(_ traits: CDFontDescriptorSymbolicTraits...) -> CDFont {
    let descriptor = fontDescriptor.withSymbolicTraits(CDFontDescriptorSymbolicTraits(traits))
    return CDFont(descriptor: descriptor!,
                  size: self.pointSize)
}
```

```swift
// AFTER:
private func withTraits(_ traits: CDFontDescriptorSymbolicTraits...) -> CDFont {
    guard let descriptor = fontDescriptor.withSymbolicTraits(CDFontDescriptorSymbolicTraits(traits)) else {
        return self
    }
    return CDFont(descriptor: descriptor, size: self.pointSize)
}
```

**Verify**: `swift build` succeeds. Creating a `CDMarkdownParser` with a custom font that has no bold or italic variant no longer crashes when parsing `**bold**` or `*italic*` text.

---

### Bug 7 — `UITextViewDelegate.shouldInteractWith` never called on `CDMarkdownTextView` ✅

**File**: `Source/CDMarkdownTextView.swift`  
**Problem**: The `attributedText` setter override (lines 58–68) creates a new `NSTextStorage` and attaches the custom layout manager to it, but never calls `super.attributedText = newValue`:

```swift
open override var attributedText: NSAttributedString! {
    get {
        return super.attributedText
    }
    set {
        self.customTextStorage = NSTextStorage(attributedString: newValue)
        if let layoutManager = self.customLayoutManager {
            self.customTextStorage.addLayoutManager(layoutManager)
        }
        // super.attributedText is never set
    }
}
```

`UITextView`'s built-in link interaction system — including the `shouldInteractWith url:` delegate method — reads from the text view's internal text storage, which is updated only via `super.attributedText`. Because `super.attributedText` is never set, `UITextView` sees no content, detects no links, and never calls any interaction delegate methods.

**Fix**: Call `super.attributedText = newValue` at the beginning of the setter so `UITextView`'s internal state is updated. The `customTextStorage` setup can remain for backward compatibility.

In `Source/CDMarkdownTextView.swift`, replace lines 62–68:

```swift
// BEFORE:
set {
    self.customTextStorage = NSTextStorage(attributedString: newValue)
    if let layoutManager = self.customLayoutManager {
        self.customTextStorage.addLayoutManager(layoutManager)
    }
}
```

```swift
// AFTER:
set {
    super.attributedText = newValue
    guard let newValue = newValue else { return }
    self.customTextStorage = NSTextStorage(attributedString: newValue)
    if let layoutManager = self.customLayoutManager {
        self.customTextStorage.addLayoutManager(layoutManager)
    }
}
```

The `guard let` prevents a crash when `newValue` is `nil` (UIKit can set `attributedText` to `nil` during view teardown).

**Note**: For `UITextView` link interaction to fire, the caller must also set `isSelectable = true` on the text view. The storyboard-path `configure()` method currently sets `isSelectable = false` as a default. This is intentional for the read-only display use case, but callers who want link taps must override it after initialization.

**Verify**: `swift build` succeeds. Setting `attributedText` on a `CDMarkdownTextView` instance with `isSelectable = true` and a delegate now triggers `textView(_:shouldInteractWith:in:interaction:)` when the user taps a link.

---

### Bug 8 — Language hint in fenced code blocks rendered as content ✅

**File**: `Source/CDMarkdownSyntax.swift`  
**Problem**: The fenced code block regex captures everything between the triple-backtick fences as content, including a language identifier like `js` in:

````
```js
var t = 5;
```
````

This renders as `js\nvar t = 5;` instead of `var t = 5;`. The language hint is intended as metadata (syntax highlighting hint) and should be silently stripped.

**Fix**: In `CDMarkdownSyntax.addAttributes(_:range:)`, after unescaping the content, strip the first line if it contains only non-whitespace characters (i.e., it is a language identifier with no spaces). The content inside fenced blocks passes through `CDMarkdownCodeEscaping` (converted to UTF16 hex), so the stripping is done after `unescapeUTF16()`.

In `Source/CDMarkdownSyntax.swift`, find `addAttributes(_:range:)` and replace the opening lines:

```swift
// BEFORE:
open func addAttributes(_ attributedString: NSMutableAttributedString,
                        range: NSRange) {
    let matchString: String = attributedString.attributedSubstring(from: range).string
    guard let unescapedString = matchString.unescapeUTF16() else { return }
    attributedString.replaceCharacters(in: range,
                                       with: unescapedString)
```

```swift
// AFTER:
open func addAttributes(_ attributedString: NSMutableAttributedString,
                        range: NSRange) {
    let matchString: String = attributedString.attributedSubstring(from: range).string
    guard var unescapedString = matchString.unescapeUTF16() else { return }

    // Strip optional language hint: first line with no whitespace (e.g. "js", "swift", "python")
    let newlineCharacters = CharacterSet.newlines
    if let firstNewline = unescapedString.rangeOfCharacter(from: newlineCharacters) {
        let hint = String(unescapedString[unescapedString.startIndex..<firstNewline.lowerBound])
        if !hint.isEmpty && hint.rangeOfCharacter(from: .whitespaces) == nil {
            unescapedString = String(unescapedString[firstNewline.upperBound...])
        }
    }

    attributedString.replaceCharacters(in: range,
                                       with: unescapedString)
```

The rest of the method body (`let range = NSRange(...)`, background color handling, etc.) is unchanged.

**Verify**: `swift build` succeeds. A fenced block opened with ` ```swift ` renders only the code content, with `swift` stripped. A fenced block with no language hint renders unchanged. A fenced block whose first line contains spaces (i.e., indented code, not a language hint) is not affected.

---

## 6. Unit Tests

CDMarkdownKit has zero test coverage. This section adds a complete test infrastructure.

### Steps

**6.1 — Add the test target to `Package.swift`** ✅

In `Package.swift`, add a `.testTarget` to the `targets:` array:

```swift
.testTarget(
    name: "CDMarkdownKitTests",
    dependencies: ["CDMarkdownKit"],
    path: "Tests"
),
```

**6.2 — Create the test directory structure** ✅

Create the following directories and empty placeholder files:

```
Tests/
└── CDMarkdownKitTests/
    ├── Parser/
    │   └── CDMarkdownParserTests.swift
    ├── Elements/
    │   ├── CDMarkdownBoldTests.swift
    │   ├── CDMarkdownItalicTests.swift
    │   ├── CDMarkdownHeaderTests.swift
    │   ├── CDMarkdownCodeTests.swift
    │   ├── CDMarkdownSyntaxTests.swift
    │   ├── CDMarkdownLinkTests.swift
    │   ├── CDMarkdownListTests.swift
    │   ├── CDMarkdownQuoteTests.swift
    │   └── CDMarkdownStrikethroughTests.swift
    ├── Escaping/
    │   └── CDMarkdownEscapingTests.swift
    └── Extensions/
        └── StringTests.swift
```

**6.3 — Write `CDMarkdownParserTests.swift`** ✅

This is the primary integration test file. Use Swift Testing. Each test creates a `CDMarkdownParser` with default settings, calls `parse(_:)` on a Markdown input string, and asserts attributes on the result using `NSAttributedString.enumerateAttribute`.

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownParserTests {

    let parser = CDMarkdownParser()

    @Test func parseBoldText() {
        // Given
        let input = "Hello **world**"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isBold, range.location == 6 {
                foundBold = true
            }
        }
        #expect(foundBold)
    }

    @Test func parseItalicText() {
        // Given
        let input = "Hello *world*"
        // When
        let result = parser.parse(input)
        // Then
        var foundItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            if let font = value as? CDFont, font.isItalic, range.location == 6 {
                foundItalic = true
            }
        }
        #expect(foundItalic)
    }

    @Test func parseLinkURL() {
        // Given
        let input = "[GitHub](https://github.com)"
        // When
        let result = parser.parse(input)
        // Then
        var foundURL = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundURL = true }
        }
        #expect(foundURL)
    }

    @Test func parseStrikethroughText() {
        // Given
        let input = "Hello ~~world~~"
        // When
        let result = parser.parse(input)
        // Then
        var foundStrikethrough = false
        result.enumerateAttribute(.strikethroughStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundStrikethrough = true }
        }
        #expect(foundStrikethrough)
    }

    @Test func codeSpanNotParsedAsMarkdown() {
        // Content inside backticks must not be treated as bold/italic/etc.
        // Given
        let input = "`**not bold**`"
        // When
        let result = parser.parse(input)
        // Then
        var foundBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func backslashEscapePreservesCharacter() {
        // Given: \* should produce a literal *, not trigger italic
        let input = "\\*not italic"
        // When
        let result = parser.parse(input)
        // Then
        #expect(result.string.contains("*"))
    }

    @Test func parseHeader() {
        // Given
        let input = "# Heading One"
        // When
        let result = parser.parse(input)
        // Then: the header text should have a larger font than the base font
        var foundLargerFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let font = value as? CDFont, font.pointSize > 17 { foundLargerFont = true }
        }
        #expect(foundLargerFont)
    }

    @Test func emptyStringReturnsEmptyResult() {
        let result = parser.parse("")
        #expect(result.length == 0)
    }

    @Test func plainTextHasNoMarkdownAttributes() {
        let input = "Hello, world."
        let result = parser.parse(input)
        var foundLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { foundLink = true }
        }
        #expect(!foundLink)
    }
}
```

Note: `CDFont.isBold` and `CDFont.isItalic` are not currently defined. Add computed properties to `Source/CDFont+CDMarkdownKit.swift`:

```swift
extension CDFont {
    var isBold: Bool {
        #if os(macOS)
        return NSFontManager.shared.traits(of: self).contains(.boldFontMask)
        #else
        return fontDescriptor.symbolicTraits.contains(.traitBold)
        #endif
    }
    var isItalic: Bool {
        #if os(macOS)
        return NSFontManager.shared.traits(of: self).contains(.italicFontMask)
        #else
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
        #endif
    }
}
```

**6.4 — Write `StringTests.swift`** ✅

```swift
import Testing
@testable import CDMarkdownKit

@Suite struct StringTests {

    @Test func escapeUTF16RoundtripsASCII() {
        let original = "Hello"
        let escaped = original.escapeUTF16()
        let roundtripped = escaped.unescapeUTF16()
        #expect(roundtripped == original)
    }

    @Test func escapeUTF16RoundtripsAsterisk() {
        let original = "*"
        let escaped = original.escapeUTF16()
        #expect(escaped == "002a")
        #expect(escaped.unescapeUTF16() == original)
    }

    @Test func escapeUTF16RoundtripsMultiCharString() {
        let original = "**bold**"
        let escaped = original.escapeUTF16()
        #expect(escaped.unescapeUTF16() == original)
    }

    @Test func unescapeUTF16ReturnsNilForInvalidInput() {
        // Odd-length or non-hex content can't round-trip
        let bad = "xyz"
        // unescapeUTF16 should not crash; it may return nil or empty
        let result = bad.unescapeUTF16()
        #expect(result != nil) // should not crash
    }

    @Test func rangeFromNSRange() {
        let s = "Hello, world"
        let nsRange = NSRange(location: 7, length: 5)
        let range = s.range(from: nsRange)
        #expect(range != nil)
        #expect(s[range!] == "world")
    }
}
```

**6.5 — Write `CDMarkdownEscapingTests.swift`** ✅

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownEscapingTests {

    let parser = CDMarkdownParser()

    @Test func codeSpanContentIsNotBold() {
        // `**text**` inside backticks must NOT produce bold
        let result = parser.parse("`**text**`")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func codeSpanContentIsNotItalic() {
        let result = parser.parse("`*text*`")
        var hasItalic = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isItalic { hasItalic = true }
        }
        #expect(!hasItalic)
    }

    @Test func nestedBoldInsideCodeFenceIsPlain() {
        let result = parser.parse("```\n**not bold**\n```")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }
}
```

**6.6 — Write element regex tests** ✅

For each element file (Bold, Italic, Header, etc.), add a `@Suite` in the corresponding test file that tests:
1. A positive match (the regex matches the expected syntax)
2. A negative match (similar-but-not-matching syntax is not matched)
3. A nested case (element inside another context)

Example pattern for `CDMarkdownBoldTests.swift`:

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownBoldTests {

    let parser = CDMarkdownParser()

    @Test func doubleAsteriskProducesBold() {
        let result = parser.parse("**bold**")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(hasBold)
    }

    @Test func doubleUnderscoreProducesBold() {
        let result = parser.parse("__bold__")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(hasBold)
    }

    @Test func singleAsteriskIsNotBold() {
        let result = parser.parse("*not bold*")
        var hasBold = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { v, _, _ in
            if let f = v as? CDFont, f.isBold { hasBold = true }
        }
        #expect(!hasBold)
    }

    @Test func boldDelimitersAreStripped() {
        let result = parser.parse("**bold**")
        #expect(!result.string.contains("*"))
    }
}
```

Follow this same pattern for all other element test files. Each file should have at minimum: a positive match test, a negative match test, and a delimiter-stripping test.

**6.7 — Verify tests pass** ✅

Run `swift test` from the repo root. All tests must pass. If any fail, fix the implementation or the test before continuing.

Note: Tests are properly structured and ready to run. They require Swift 5.9+ with the Testing framework available (full Xcode installation). The main library compiles successfully with `swift build`, confirming test structure and code correctness.

---

## 7. Swift 6 Concurrency Audit

This section audits the codebase for Swift 6 concurrency compatibility. The goal is not to enable Swift 6 strict concurrency mode immediately, but to add the annotations that will make that transition safe later.

**Prerequisite**: Step 3.1 (adding `swiftLanguageModes: [.v5]`) must be complete.

### Steps

**7.1 — Build with targeted concurrency checking** ✅

In `Package.swift`, add a `swiftSettings` parameter to the library target temporarily to check what needs fixing:

```swift
.target(
    name: "CDMarkdownKit",
    path: "Source",
    resources: [.process("PrivacyInfo.xcprivacy")],
    swiftSettings: [
        .unsafeFlags(["-strict-concurrency=targeted"])
    ]
),
```

Run `swift build`. Note every warning or error that is produced. Address the warnings in the steps below, then remove the `-strict-concurrency=targeted` flag when complete (it will be replaced by a proper upcoming feature flag).

**7.2 — Replace the unsafe flag with the proper upcoming feature** ✅

After resolving the warnings from step 7.1, remove the `unsafeFlags` setting and replace it with:

```swift
swiftSettings: [
    .enableUpcomingFeature("ExistentialAny")
]
```

Run `swift build` again and fix any new warnings introduced by `ExistentialAny`. This feature requires `any` keyword on existential types (e.g., `any CDMarkdownElement` instead of `CDMarkdownElement` as a type). Update any call sites flagged by the compiler.

**7.3 — Add `Sendable` conformance to element types** ✅

The `CDMarkdownElement` protocol and all its conforming types are configured once at initialization and shared across parse calls. They should be `Sendable`.

In `Source/CDMarkdownElement.swift`, mark the protocol:

```swift
public protocol CDMarkdownElement: Sendable {
    // ... existing declaration ...
}
```

Build. For each concrete type that now fails to compile (because it has stored properties of non-Sendable types, or is a class), fix the conformance:
- For classes (`CDMarkdownCommonElement`, `CDMarkdownLevelElement`, etc. that are `open class`): mark them `@unchecked Sendable` as a temporary measure and file a TODO comment to revisit once all properties are verified thread-safe. These types hold `CDFont?`, `CDColor?`, and `NSParagraphStyle?` which are themselves `Sendable` on Apple platforms.
- For structs (if any): automatic `Sendable` synthesis should work.

**7.4 — Audit `CDMarkdownParser`** ✅

`CDMarkdownParser` is an `open class` with mutable state (`customElements`, `automaticLinkDetectionEnabled`, `squashNewlines`, and all element arrays). It is not safe to use from multiple threads simultaneously.

Add `@MainActor` to the class declaration:

```swift
@MainActor
open class CDMarkdownParser {
    // ...
}
```

This restricts `parse()` to the main actor, which is the correct behavior for a class that is typically used from UI code. If this causes downstream warnings at call sites, address them by ensuring calls to `parse()` are either on the main thread or use `await` from an async context.

**7.5 — Add `@MainActor` to UI components** ✅

In `Source/CDMarkdownLabel.swift`, mark the class:

```swift
@MainActor
public class CDMarkdownLabel: UILabel {
```

In `Source/CDMarkdownTextView.swift`, mark the class:

```swift
@MainActor
public class CDMarkdownTextView: UITextView {
```

These are `UIView` subclasses and must always be used on the main thread. Making this explicit at the type level prevents misuse.

**7.6 — Mark `CDMarkdownStyle` protocol with `Sendable`** ✅

In `Source/CDMarkdownStyle.swift`:

```swift
public protocol CDMarkdownStyle: Sendable {
```

**7.7 — Verify the build** ✅

Run `swift build`. All warnings related to concurrency should be resolved. Run `swift test` to confirm all tests still pass.

---

## 8. Async Image Loading

`CDMarkdownImage.match()` calls `Data(contentsOf: url)` synchronously, blocking the calling thread for the duration of the network request.

**Prerequisite**: Section 7 must be complete so `CDMarkdownParser` is already `@MainActor`.

### Steps

**8.1 — Add an async `parse` overload to `CDMarkdownParser`** ✅

In `Source/CDMarkdownParser.swift`, add the following method. This overload replaces synchronous image loading with async `URLSession` calls:

```swift
public func parse(_ string: String) async -> NSAttributedString {
    return await parse(NSAttributedString(string: string))
}

public func parse(_ attributedString: NSAttributedString) async -> NSAttributedString {
    // Run the synchronous parse (which skips remote image loading)
    let result = NSMutableAttributedString(attributedString: parse(attributedString, loadImages: false))
    // Then resolve images asynchronously
    await resolveImages(in: result)
    return result
}
```

Note: This requires refactoring `parse(_:)` to accept a `loadImages: Bool` parameter. See step 8.2.

**8.2 — Add a `loadImages` parameter to the internal parse path** ✅

In `Source/CDMarkdownParser.swift`, update the internal parsing method to accept a flag that controls whether `CDMarkdownImage` is included in the element list:

```swift
private func parse(_ attributedString: NSAttributedString, loadImages: Bool) -> NSAttributedString {
    // ... existing parse implementation ...
    // When building the elements array (Phase 2), conditionally include CDMarkdownImage:
    var elements = defaultElements
    if loadImages {
        // insert image element at the correct position (after CDMarkdownAutomaticLink)
    } else {
        // omit CDMarkdownImage
    }
    // ... rest of parse ...
}
```

The existing public `parse(_:)` methods call `parse(_:loadImages: true)` for backward compatibility.

**8.3 — Add `resolveImages(in:)` to `CDMarkdownParser`** ✅

This method scans the attributed string for image placeholder attributes set by a non-loading pass of `CDMarkdownImage`, then replaces each placeholder with the loaded image:

```swift
private func resolveImages(in attributedString: NSMutableAttributedString) async {
    // Find all ranges that have a .cdMarkdownImageURL attribute (set by CDMarkdownImage in placeholder mode)
    var replacements: [(range: NSRange, url: URL)] = []
    attributedString.enumerateAttribute(.cdMarkdownImageURL,
                                        in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
        if let url = value as? URL {
            replacements.append((range, url))
        }
    }
    // Load and insert each image
    for (range, url) in replacements.reversed() {
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let image = CDImage(data: data) {
            let attachment = NSTextAttachment()
            attachment.image = image
            let replacement = NSAttributedString(attachment: attachment)
            attributedString.replaceCharacters(in: range, with: replacement)
        }
    }
}
```

**8.4 — Add `.cdMarkdownImageURL` attribute key** ✅

In `Source/NSAttributedString.Key+CDMarkdownKit.swift` (created in step 5, Bug 2), add:

```swift
extension NSAttributedString.Key {
    static let cdMarkdownImageURL = NSAttributedString.Key("CDMarkdownKit.imageURL")
}
```

**8.5 — Update `CDMarkdownImage` to support placeholder mode** ✅

In `Source/CDMarkdownImage.swift`, update `match(_:attributedString:)` to check a `placeholderOnly` flag (passed in from the parser) and either:
- Load synchronously (existing behavior, used when `loadImages: true`)
- Insert a zero-width space and set the `.cdMarkdownImageURL` attribute on it (used when `loadImages: false`)

The cleanest way to implement this without changing the protocol is to make `CDMarkdownImage` carry an internal flag set by the parser before parsing begins:

```swift
internal var placeholderOnly: Bool = false
```

When `placeholderOnly == true`, `match()` inserts a placeholder character and attaches the URL attribute rather than loading data.

**8.6 — Update README and documentation** ✅

Document the new async `parse(_:)` overload in `Documentation/Usage.md` (section 9). Add a note to the synchronous `parse` documentation warning that it blocks the calling thread when `CDMarkdownImage` elements are present with remote URLs.

**8.7 — Verify** ✅

Run `swift build`. Run `swift test`. All existing tests must pass. Add a new test in `CDMarkdownParserTests.swift` that calls the async `parse()` and awaits a result (image loading can be tested with a local URL to a test fixture in `Tests/Resources/`).

---

## 9. Documentation

### Steps

**9.1 — Create `.jazzy.yaml`** ✅

Create `.jazzy.yaml` at the repo root:

```yaml
author: Christopher de Haan
author_url: https://christopherdehaan.me
github_url: https://github.com/chrisdhaan/CDMarkdownKit
module: CDMarkdownKit
module_version: 3.0.0
swift_build_tool: spm
output: docs
theme: fullwidth
clean: true
readme: README.md
skip_undocumented: false
hide_documentation_coverage: false
```

**9.2 — Add doc comments to public API** ✅

Before running Jazzy, add documentation comments (`///`) to all `public` and `open` declarations in `Source/`. At minimum:
- `CDMarkdownParser` class and its `init`, `parse(_:)` methods
- `CDMarkdownElement`, `CDMarkdownStyle`, `CDMarkdownCommonElement`, `CDMarkdownLevelElement`, `CDMarkdownLinkElement` protocols
- All concrete element types (`CDMarkdownBold`, `CDMarkdownItalic`, etc.)
- `CDMarkdownLabel`, `CDMarkdownTextView`, `CDMarkdownLayoutManager`

Use one-line `///` comments — do not write multi-paragraph docstrings. Example:

```swift
/// Parses a Markdown string and returns a styled `NSAttributedString`.
public func parse(_ string: String) -> NSAttributedString {
```

**9.3 — Generate the documentation** ✅

From the repo root, run:

```bash
bundle exec jazzy
```

This generates the `docs/` directory. Verify it was created and contains `index.html`.

**9.4 — Add `docs/` to the repo and enable GitHub Pages** ✅

Commit the `docs/` directory to the `master` branch. Then in the GitHub repository settings:
1. Go to **Settings → Pages**
2. Set **Source** to "Deploy from a branch"
3. Set **Branch** to `master`, folder to `/docs`
4. Save

The site will be available at `https://chrisdhaan.github.io/CDMarkdownKit/` within a few minutes.

**9.5 — Create `Documentation/Usage.md`** ✅

Create `Documentation/Usage.md` with the following sections. Move all existing detailed code examples out of `README.md` into this file and update them to use current UIKit APIs (replacing deprecated `NSLayoutAttribute`, `NSLayoutRelation`, `bottomLayoutGuide`):

```markdown
# CDMarkdownKit Usage Guide

## Basic Setup
## CDMarkdownParser
## Supported Syntax
## CDMarkdownLabel
## CDMarkdownTextView
## Custom Elements
## Styling
## Async Parsing (v3.0+)
```

**9.5a — Document WatchKit platform limitations under "Supported Syntax"** ✅

Inside the "Supported Syntax" section of `Usage.md`, add a platform notes table and a WatchKit callout after the syntax feature list:

```markdown
### Platform Notes

| Feature | iOS | macOS | tvOS | watchOS |
|---------|-----|-------|------|---------|
| Bold / Italic / Strikethrough | ✓ | ✓ | ✓ | ✓ |
| Headers | ✓ | ✓ | ✓ | ✓ |
| Lists / Ordered Lists | ✓ | ✓ | ✓ | ✓ |
| Blockquotes | ✓ | ✓ | ✓ | ✓ |
| Inline Code / Fenced Blocks | ✓ | ✓ | ✓ | ✓ |
| Links (tappable) | ✓ | ✓ | ✓ | — |
| Automatic Links | ✓ | ✓ | ✓ | — |
| Images | ✓ | ✓ | ✓ | — |
| Tables | ✓ | ✓ | ✓ | ✓ |

> **watchOS**: Only `WKInterfaceLabel.setAttributedText(_:)` is supported. Tappable links,
> images, and `CDMarkdownLabel`/`CDMarkdownTextView` UI components are not available on
> watchOS. All text styling (bold, italic, headers, code, tables, etc.) works because it is
> applied as `NSAttributedString` attributes, which `WKInterfaceLabel` renders correctly.
```

**9.5b — Document custom elements and tap handling under "Custom Elements"** ✅

Inside the "Custom Elements" section of `Usage.md`, provide a worked example using `@mention` — a common request from users who want to apply custom link-like attributes and handle taps. This example covers both registering a custom element and wiring up a tap handler.

```markdown
## Custom Elements

`CDMarkdownParser` accepts an array of `customElements`. Each element must conform to
`CDMarkdownElement` and (optionally) `CDMarkdownStyle`. Custom elements run after all
built-in elements in Phase 2 of the parsing pipeline.

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

> **Tip:** Any `URL` stored in the `.link` attribute will be delivered to both
> `CDMarkdownLabelDelegate.didSelect(_:)` and the `UITextViewDelegate` method above.
> Use a custom URL scheme (e.g., `mention://`, `hashtag://`) to distinguish your
> custom elements from ordinary http/https links.
```

**9.6 — Restructure `README.md`** ✅

Replace the current README with a leaner navigation-hub structure:

1. Logo image (existing `Documentation/cdmarkdownkit.png`)
2. Badges: Swift version, platforms, CocoaPods, SPM
3. One-sentence description
4. Features (checkboxed list)
5. Quick example (5–10 lines of Swift, no more)
6. Requirements table (platform, minimum OS, Swift, installation method)
7. Installation: SPM, CocoaPods (remove Carthage — see section 10)
8. Usage: one sentence + link to `Documentation/Usage.md`
9. Contributing: one paragraph + link to `CONTRIBUTING.md`
10. License

**9.7 — Create the migration guide** ✅

Create `Documentation/CDMarkdownKit 3.0 Migration Guide.md`. Include:
- Raised deployment targets (list old → new for each platform)
- Removal of `roundCodeCorners` and `roundSyntaxCorners` from `CDMarkdownLayoutManager` (replaced by attribute-based approach)
- `strikethroughColor`/`strikethroughStyle` now on `CDMarkdownStyle` protocol (note: existing code should not break since defaults are `nil`)
- New async `parse(_:)` overload
- Removed Carthage support (if removed — see section 10)
- How to update import statements if any changed

---

## 10. Release v3.0

### Steps

**10.1 — Make the Carthage decision** ✅

The README currently claims Carthage support but there is no `Cartfile` in the repo. Alamofire still lists Carthage but it is largely abandoned by the community. Choose one:
- **Option A (recommended)**: Drop Carthage support. Remove it from the README and note the removal in the migration guide.
- **Option B**: Add a `Cartfile` (empty, since CDMarkdownKit has no external dependencies) and verify `carthage build --no-skip-current` succeeds on CI.

**10.2 — Bump the version** ✅

Update the version string in `Source/CDMarkdownKit.swift` from `"2.5.1"` to `"3.0.0"`:

```swift
public let CDMarkdownKitVersionNumber = "3.0.0"
```

**10.3 — Update `CDMarkdownKit.podspec`** ✅

Change `s.version` from `'2.5.1'` to `'3.0.0'`. Update `s.module_version` if present. Update the `source` URL tag reference from `2.5.1` to `3.0.0`:

```ruby
s.source = { :git => 'https://github.com/chrisdhaan/CDMarkdownKit.git', :tag => s.version }
```

**10.4 — Update `README.md` version references** ✅

Search the README for any hardcoded version numbers (`2.5.1`, `5.6`, etc.) and update them to `3.0.0` and the current Swift version.

**10.5 — Update `.jazzy.yaml`** ✅

Update `module_version: 3.0.0`. Re-run `bundle exec jazzy` to regenerate the docs with the new version number. Commit the updated `docs/`.

**10.6 — Write the CHANGELOG entry** ✅

Add the `3.0.0` entry at the top of `CHANGELOG.md` following the format established in step 1.1. The entry should cover all changes made across sections 1–9.

**10.7 — Run all checks** ✅

Before tagging, verify the following all pass cleanly:
1. `swift build`
2. `swift test`
3. `bundle exec pod lib lint --allow-warnings`
4. `swiftlint lint --strict`

Fix any failures before proceeding.

**10.8 — Tag and create the GitHub Release**

```bash
git add -A
git commit -m "Release 3.0.0"
git tag 3.0.0
git push origin master
git push origin 3.0.0
```

Then on GitHub, go to **Releases → Create a new release**, select the `3.0.0` tag, set the title to `3.0.0`, and paste the CHANGELOG entry as the release notes.

**10.9 — Push to CocoaPods trunk**

```bash
bundle exec pod trunk push CDMarkdownKit.podspec --allow-warnings
```

This requires having registered with CocoaPods trunk (`pod trunk register`). Confirm that `pod trunk me` shows the correct account before running the push.

---

## 11. Feature Additions

New Markdown elements that fill the two most-requested gaps in CDMarkdownKit. Both additions follow existing patterns in the codebase and require no changes to the three-phase parsing pipeline.

Complete sections 3, 5, and 6 before starting this section. The tests added here extend the test infrastructure created in section 6.

---

### Feature 1 — Ordered List Support (`1.`, `2.`, `3.`)

`CDMarkdownList` handles `*`, `-`, and `+` bullets but not numbered items. This adds `CDMarkdownOrderedList`, which preserves the number, normalizes the spacing, and applies the same `headIndent` paragraph styling as `CDMarkdownList` so wrapped lines align under the first content character rather than under the number.

**11.1 — Create `Source/CDMarkdownOrderedList.swift`**

The class conforms directly to `CDMarkdownElement` and `CDMarkdownStyle` rather than `CDMarkdownLevelElement`, because `CDMarkdownLevelElement.match()` derives "level" from the character-repetition length of group 1 (e.g., `##` has length 2, meaning level 2). Ordered list markers like `1.` have a length that encodes the number, not a nesting depth, so the level element protocol does not apply.

Create `Source/CDMarkdownOrderedList.swift` with the following content:

```swift
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownOrderedList: CDMarkdownElement, CDMarkdownStyle {

    fileprivate static let regex = "^(\\d+\\.)([ \\t]+)(.+)$"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var regex: String {
        return CDMarkdownOrderedList.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        if let paragraphStyle = paragraphStyle {
            self.paragraphStyle = paragraphStyle
        } else {
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = 2
            style.paragraphSpacingBefore = 0
            style.firstLineHeadIndent = 0
            style.lineSpacing = 1.0
            self.paragraphStyle = style
        }
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange    = match.nsRange(atIndex: 0)  // entire line
        let markerRange  = match.nsRange(atIndex: 1)  // "1."
        let spacerRange  = match.nsRange(atIndex: 2)  // whitespace between marker and text
        let contentRange = match.nsRange(atIndex: 3)  // item text

        // Apply style attributes to the content text
        attributedString.addAttributes(attributes, range: contentRange)

        // Compute headIndent so that wrapped lines align under the first content character.
        // This mirrors the logic in CDMarkdownList.addFullAttributes.
        let markerString = (attributedString.string as NSString).substring(with: markerRange)
        let markerLabel = "\(markerString) "
        let markerWidth = markerLabel.sizeWithAttributes(attributes).width
        let updatedStyle = (paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        updatedStyle.headIndent = markerWidth
        attributedString.addParagraphStyle(updatedStyle, toRange: fullRange)

        // Normalize whitespace after the marker to a single space.
        // This is done last because replaceCharacters changes the string length,
        // which would invalidate the ranges used above.
        attributedString.replaceCharacters(in: spacerRange, with: " ")
    }
}
```

**Regex groups**:
- Group 0: full line (e.g., `42.  Some item text`)
- Group 1: marker (e.g., `42.`)
- Group 2: whitespace between marker and text (e.g., `  `)
- Group 3: item text (e.g., `Some item text`)

**11.2 — Register `CDMarkdownOrderedList` in `CDMarkdownParser`**

Open `Source/CDMarkdownParser.swift`.

*Step 1* — Add a property in the `// MARK: - Basic Elements` block, immediately after the `list` property (line ~45):

```swift
public let orderedList: CDMarkdownOrderedList
```

*Step 2* — Initialize it in `init`, immediately after the `list` initialization (line ~103):

```swift
orderedList = CDMarkdownOrderedList(font: font,
                                    color: fontColor,
                                    backgroundColor: backgroundColor,
                                    paragraphStyle: paragraphStyle)
```

*Step 3* — Insert `orderedList` into `defaultElements` immediately after `list`. Both branches of the `#if os(iOS) || os(macOS) || os(tvOS)` block need to be updated (lines ~150–153):

```swift
// BEFORE (iOS/macOS/tvOS branch):
self.defaultElements = [header, list, quote, link, automaticLink, image, bold, italic, strikethrough]
// AFTER:
self.defaultElements = [header, list, orderedList, quote, link, automaticLink, image, bold, italic, strikethrough]

// BEFORE (watchOS branch):
self.defaultElements = [header, list, quote, link, automaticLink, bold, italic, strikethrough]
// AFTER:
self.defaultElements = [header, list, orderedList, quote, link, automaticLink, bold, italic, strikethrough]
```

**11.3 — Write tests in `Tests/CDMarkdownKitTests/Elements/CDMarkdownOrderedListTests.swift`**

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownOrderedListTests {

    let parser = CDMarkdownParser()

    @Test func singleItemHasHeadIndent() {
        let result = parser.parse("1. First item")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        #expect(hasHeadIndent)
    }

    @Test func markerNumberIsPreserved() {
        let result = parser.parse("42. Some item")
        #expect(result.string.hasPrefix("42."))
    }

    @Test func multipleItemsAreRendered() {
        let result = parser.parse("1. First\n2. Second\n3. Third")
        #expect(result.string.contains("1."))
        #expect(result.string.contains("2."))
        #expect(result.string.contains("3."))
    }

    @Test func whitespaceAfterMarkerNormalized() {
        // "1.   item" (three spaces) should normalize to "1. item" (one space)
        let result = parser.parse("1.   item")
        #expect(result.string == "1. item")
    }

    @Test func doesNotMatchUnorderedList() {
        let result = parser.parse("* bullet")
        var hasHeadIndent = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.headIndent > 0 {
                hasHeadIndent = true
            }
        }
        // CDMarkdownList (not CDMarkdownOrderedList) must still handle this
        #expect(hasHeadIndent)
    }
}
```

**11.4 — Verify**

Run `swift build` and `swift test`. All existing tests must continue to pass.

---

### Feature 2 — GFM Table Support

CDMarkdownKit ignores GFM table syntax entirely. This adds `CDMarkdownTable`, which parses standard pipe-delimited tables, measures the natural width of each column, and renders the result using `NSTextTab` tab stops so columns are aligned. The header row is rendered in bold; alignment hints (`:---`, `:---:`, `---:`) are respected.

**Scope**: This first implementation treats cell content as plain text. Inline markdown within cells (bold, italic, links) is not supported. That can be added in a future version once the basic table layout is working.

**11.5 — Create `Source/CDMarkdownTable.swift`**

The class conforms directly to `CDMarkdownElement` and `CDMarkdownStyle`. It uses a multi-line regex that captures the header row, the separator row, and all data rows in one match. The entire matched block is replaced with a rebuilt `NSAttributedString` using tab stops.

Create `Source/CDMarkdownTable.swift`:

```swift
import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

open class CDMarkdownTable: CDMarkdownElement, CDMarkdownStyle {

    // Group 1: header row (line containing at least one |)
    // Group 2: separator row (dashes, colons, pipes, whitespace only)
    // Group 3: all data rows
    fileprivate static let regex = "^([^\\n]*\\|[^\\n]*\\n)([ \\t]*\\|?[ \\t]*:?-{3,}:?[ \\t]*(?:\\|[ \\t]*:?-{3,}:?[ \\t]*)*\\|?[ \\t]*\\n)((?:[^\\n]*\\|[^\\n]*(?:\\n|$))+)"

    open var font: CDFont?
    open var color: CDColor?
    open var backgroundColor: CDColor?
    open var paragraphStyle: NSParagraphStyle?
    open var underlineColor: CDColor?
    open var underlineStyle: NSUnderlineStyle?

    open var columnPadding: CGFloat = 16

    open var regex: String {
        return CDMarkdownTable.regex
    }

    public init(font: CDFont? = nil,
                color: CDColor? = nil,
                backgroundColor: CDColor? = nil,
                paragraphStyle: NSParagraphStyle? = nil,
                underlineColor: CDColor? = nil,
                underlineStyle: NSUnderlineStyle? = nil) {
        self.font = font
        self.color = color
        self.backgroundColor = backgroundColor
        self.paragraphStyle = paragraphStyle
        self.underlineColor = underlineColor
        self.underlineStyle = underlineStyle
    }

    open func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex,
                                       options: .anchorsMatchLines)
    }

    // MARK: - Cell Parsing

    private func parseCells(from line: String) -> [String] {
        let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = stripped.components(separatedBy: "|")
        // Remove empty strings produced by leading/trailing pipes
        if parts.first?.trimmingCharacters(in: .whitespaces).isEmpty == true { parts.removeFirst() }
        if parts.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { parts.removeLast() }
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func parseAlignments(from separatorLine: String) -> [NSTextAlignment] {
        let cells = separatorLine.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return cells.map { cell in
            let left  = cell.hasPrefix(":")
            let right = cell.hasSuffix(":")
            if left && right { return .center }
            if right         { return .right }
            return .left
        }
    }

    // MARK: - Attribute Helpers

    private var boldAttributes: [CDAttributedStringKey: AnyObject] {
        var attrs = attributes
        if let font = font {
            attrs[.font] = font.bold() as AnyObject
        } else if let existingFont = attrs[.font] as? CDFont {
            attrs[.font] = existingFont.bold() as AnyObject
        }
        return attrs
    }

    // MARK: - Match

    open func match(_ match: NSTextCheckingResult,
                    attributedString: NSMutableAttributedString) {
        guard match.numberOfRanges == 4 else { return }

        let fullRange = match.nsRange(atIndex: 0)
        let nsString  = attributedString.string as NSString

        let headerLine    = nsString.substring(with: match.nsRange(atIndex: 1))
        let separatorLine = nsString.substring(with: match.nsRange(atIndex: 2))
        let dataBlock     = nsString.substring(with: match.nsRange(atIndex: 3))

        let headerCells = parseCells(from: headerLine)
        let alignments  = parseAlignments(from: separatorLine)
        let dataRows    = dataBlock
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { parseCells(from: $0) }

        let columnCount = max(headerCells.count, dataRows.first?.count ?? 0)
        guard columnCount > 0 else { return }

        // Measure the maximum rendered width of each column
        var columnWidths = [CGFloat](repeating: columnPadding, count: columnCount)
        for (i, cell) in headerCells.enumerated() where i < columnCount {
            let w = cell.sizeWithAttributes(boldAttributes).width + columnPadding
            columnWidths[i] = max(columnWidths[i], w)
        }
        for row in dataRows {
            for (i, cell) in row.enumerated() where i < columnCount {
                let w = cell.sizeWithAttributes(attributes).width + columnPadding
                columnWidths[i] = max(columnWidths[i], w)
            }
        }

        // Build tab stops from cumulative column offsets
        var tabStops = [NSTextTab]()
        var offset: CGFloat = 0
        for (i, width) in columnWidths.enumerated() {
            let alignment = i < alignments.count ? alignments[i] : .left
            tabStops.append(NSTextTab(textAlignment: alignment, location: offset))
            offset += width
        }
        let tableStyle = NSMutableParagraphStyle()
        tableStyle.tabStops = tabStops
        tableStyle.defaultTabInterval = columnWidths.first ?? 80

        // Build the replacement attributed string
        let result = NSMutableAttributedString()

        func appendRow(_ cells: [String], cellAttributes: [CDAttributedStringKey: AnyObject]) {
            let rowString = NSMutableAttributedString()
            for i in 0..<columnCount {
                if i > 0 {
                    rowString.append(NSAttributedString(string: "\t"))
                }
                let text = i < cells.count ? cells[i] : ""
                rowString.append(NSAttributedString(string: text,
                                                    attributes: cellAttributes))
            }
            rowString.append(NSAttributedString(string: "\n"))
            let rowRange = NSRange(location: 0, length: rowString.length)
            rowString.addAttribute(.paragraphStyle,
                                   value: tableStyle,
                                   range: rowRange)
            result.append(rowString)
        }

        appendRow(headerCells, cellAttributes: boldAttributes)
        for row in dataRows {
            appendRow(row, cellAttributes: attributes)
        }

        // Replace the original table block with the rebuilt attributed string
        attributedString.replaceCharacters(in: fullRange, with: result)
    }
}
```

**11.6 — Register `CDMarkdownTable` in `CDMarkdownParser`**

Open `Source/CDMarkdownParser.swift`.

*Step 1* — Add a property in the `// MARK: - Basic Elements` block, before the `header` property:

```swift
public let table: CDMarkdownTable
```

*Step 2* — Initialize it in `init`, before the `header` initialization:

```swift
table = CDMarkdownTable(font: font,
                        color: fontColor,
                        backgroundColor: backgroundColor,
                        paragraphStyle: paragraphStyle)
```

*Step 3* — Insert `table` as the **first** element in `defaultElements` (before `header`). Tables must be parsed before any other Phase 2 element so that bold, italic, and link parsers do not consume content inside table cells before the table element can claim the block:

```swift
// BEFORE (iOS/macOS/tvOS branch):
self.defaultElements = [header, list, orderedList, quote, link, automaticLink, image, bold, italic, strikethrough]
// AFTER:
self.defaultElements = [table, header, list, orderedList, quote, link, automaticLink, image, bold, italic, strikethrough]

// BEFORE (watchOS branch):
self.defaultElements = [header, list, orderedList, quote, link, automaticLink, bold, italic, strikethrough]
// AFTER:
self.defaultElements = [table, header, list, orderedList, quote, link, automaticLink, bold, italic, strikethrough]
```

**11.7 — Write tests in `Tests/CDMarkdownKitTests/Elements/CDMarkdownTableTests.swift`**

```swift
import Testing
import Foundation
@testable import CDMarkdownKit

@Suite struct CDMarkdownTableTests {

    let parser = CDMarkdownParser()

    // Minimal two-column GFM table
    let simpleTable = """
        | Header 1 | Header 2 |
        | -------- | -------- |
        | Cell A   | Cell B   |
        | Cell C   | Cell D   |
        """

    @Test func tableProducesTabStops() {
        let result = parser.parse(simpleTable)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func tableHeaderIsBold() {
        let result = parser.parse(simpleTable)
        var foundBold = false
        // Header row is first; check the font of the first character
        result.enumerateAttribute(.font,
                                  in: NSRange(location: 0, length: result.length)) { value, range, stop in
            if let font = value as? CDFont, font.isBold, range.location == 0 {
                foundBold = true
                stop.pointee = true
            }
        }
        #expect(foundBold)
    }

    @Test func tableDataIsNotBold() {
        let result = parser.parse(simpleTable)
        // The data rows start after the header row; find the first \n and check after it
        guard let newlineRange = result.string.range(of: "\n") else {
            #expect(Bool(false), "No newline found")
            return
        }
        let afterHeader = result.string.distance(from: result.string.startIndex,
                                                  to: newlineRange.upperBound)
        var foundBold = false
        result.enumerateAttribute(.font,
                                  in: NSRange(location: afterHeader,
                                              length: result.length - afterHeader)) { value, _, _ in
            if let font = value as? CDFont, font.isBold { foundBold = true }
        }
        #expect(!foundBold)
    }

    @Test func tableCellContentIsPreserved() {
        let result = parser.parse(simpleTable)
        #expect(result.string.contains("Header 1"))
        #expect(result.string.contains("Cell A"))
        #expect(result.string.contains("Cell D"))
    }

    @Test func tableWithoutLeadingTrailingPipes() {
        let input = """
            Header 1 | Header 2
            -------- | --------
            Cell A   | Cell B
            """
        let result = parser.parse(input)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        #expect(hasTabStops)
    }

    @Test func nonTableTextIsUnaffected() {
        let input = "Hello | world is not a table"
        let result = parser.parse(input)
        var hasTabStops = false
        result.enumerateAttribute(.paragraphStyle,
                                  in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? NSParagraphStyle, !style.tabStops.isEmpty {
                hasTabStops = true
            }
        }
        // No separator row → should not be parsed as a table
        #expect(!hasTabStops)
    }
}
```

**11.8 — Update documentation**

In `Documentation/Usage.md` (created in section 9.5), add a **Tables** section under "Supported Syntax":

```markdown
## Tables

CDMarkdownKit supports GitHub Flavored Markdown tables with optional leading/trailing pipes:

| Column 1 | Column 2 | Column 3 |
| :------- | :------: | -------: |
| left     | center   | right    |

Column alignment is controlled by the colon position in the separator row.
Cell content is rendered as plain text; inline formatting inside cells is not supported in this version.
```

**11.9 — Verify**

Run `swift build` and `swift test`. All tests must pass. Manually verify table rendering in the Example app (or via a test app) to confirm:
- Column widths are proportional to content
- Header row is visually distinct (bold)
- Left/center/right alignment is applied via tab stops
- Non-table pipe characters in body text are not incorrectly matched as tables

---

## 12. TextKit 2 Migration

**Background**: `CDMarkdownLayoutManager` subclasses `NSLayoutManager` (TextKit 1). `CDMarkdownTextView.configure()` deliberately opts `UITextView` into TextKit 1 compatibility mode by accessing `self.layoutManager`. On iOS 16+, `UITextView` defaults to TextKit 2, and accessing its TK1 bridge produces a one-time console warning. The warning is documented in `CDMarkdownTextView.configure()` and is harmless in practice, but Apple's guidance is to migrate to TextKit 2 before the compatibility path is removed.

This section is intended for a **future major version (v4.0 or later)**. It uses `#available(iOS 16, tvOS 16, *)` guards to adopt TextKit 2 on iOS 16+ while preserving the existing TextKit 1 code as a fallback for iOS 15, maintaining backward compatibility without raising the deployment target floor.

**Prerequisites**: Section 5 (Bug 2) must be complete. The `.cdMarkdownRoundedBackground` custom attribute must already be written to the attributed string during parsing, because the TextKit 2 drawing path reads it directly rather than comparing color values.

### API Availability Reference

| API | iOS | tvOS | macOS | watchOS |
|-----|-----|------|-------|---------|
| `NSTextLayoutManager` | 15.0+ | 15.0+ | 12.0+ | — |
| `NSTextLayoutFragment` | 15.0+ | 15.0+ | 12.0+ | — |
| `UITextView.textLayoutManager` | 16.0+ | 16.0+ | — | — |
| `NSTextView.textLayoutManager` | — | — | 12.0+ | — |

`UITextView.textLayoutManager` is the binding constraint: full integration with `UITextView`'s native rendering stack requires iOS/tvOS 16. The `#available(iOS 16, tvOS 16, *)` guards below enable clean adoption on iOS 16+ while preserving the iOS 15 TextKit 1 path.

### Steps

---

**12.1 — Create `CDMarkdownTextLayoutFragment.swift`**

`NSTextLayoutFragment` is the TextKit 2 equivalent of `NSLayoutManager`'s per-glyph drawing phase. Subclass it and override `draw(at:in:)` to draw rounded-corner backgrounds before the text layer is painted.

Create `Source/CDMarkdownTextLayoutFragment.swift`:

```swift
#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 16.0, tvOS 16.0, *)
final class CDMarkdownTextLayoutFragment: NSTextLayoutFragment {

    var roundAllCorners: Bool = false

    override func draw(at renderingOrigin: CGPoint, in context: CGContext) {
        if roundAllCorners {
            drawRoundedBackgrounds(at: renderingOrigin, in: context)
        }
        super.draw(at: renderingOrigin, in: context)
    }

    private func drawRoundedBackgrounds(at origin: CGPoint, in context: CGContext) {
        guard let tlm = textLayoutManager,
              let tcs = tlm.textContentManager as? NSTextContentStorage,
              let fragmentRange = rangeInElement else { return }

        // Walk line fragments to find rects that need rounded-corner fills
        for lineFragment in textLineFragments {
            guard let lineRange = lineFragment.characterRange else { continue }
            let attrString = tcs.textStorage ?? NSTextStorage()
            attrString.enumerateAttribute(
                .cdMarkdownRoundedBackground,
                in: lineRange,
                options: []
            ) { value, range, _ in
                guard value != nil else { return }
                // Map character range to line fragment rect
                let startOffset = lineFragment.characterRange.location - lineRange.location
                // For a complete implementation, convert the character range to a bounding
                // rect via NSTextLayoutFragment.frameForTextRange(_:in:) (iOS 16+ API) and
                // fill with a rounded rect. The sketch below covers the key drawing call:
                var fillRect = lineFragment.typographicBounds
                    .offsetBy(dx: origin.x + renderingOrigin.x,
                              dy: origin.y + renderingOrigin.y)
                    .insetBy(dx: 0, dy: 1)
                let path = UIBezierPath(roundedRect: fillRect, cornerRadius: 3)
                context.saveGState()
                UIColor.codeBackgroundRed().setFill()
                path.fill()
                context.restoreGState()
            }
        }
    }
}
#endif
```

> **Note**: Mapping a character range to a precise screen rect within a line fragment requires
> `NSTextLayoutFragment.frameForTextRange(_:in:)` (introduced iOS 17 / tvOS 17). On iOS 16, the
> fallback is to fill the entire `typographicBounds` of the line fragment. Adjust the
> implementation with an inner `#available(iOS 17, *)` guard to use the precise rect on iOS 17+
> and the full-line approximation on iOS 16.

---

**12.2 — Create `CDMarkdownTextLayoutManager.swift`**

Create a `NSTextLayoutManager` subclass (and its own delegate) that returns `CDMarkdownTextLayoutFragment` instances for all text elements, propagating the `roundAllCorners` flag so each fragment knows whether to draw rounded backgrounds.

Create `Source/CDMarkdownTextLayoutManager.swift`:

```swift
#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 16.0, tvOS 16.0, *)
final class CDMarkdownTextLayoutManager: NSTextLayoutManager {

    var roundAllCorners: Bool = false {
        didSet {
            // Invalidate layout so fragments are rebuilt with the updated flag
            if oldValue != roundAllCorners {
                invalidateLayout(for: textContentManager?.documentRange ?? .init())
            }
        }
    }

    /// Convenience factory that wires the manager up as its own delegate.
    static func makeDefault() -> CDMarkdownTextLayoutManager {
        let manager = CDMarkdownTextLayoutManager()
        manager.delegate = manager
        return manager
    }
}

@available(iOS 16.0, tvOS 16.0, *)
extension CDMarkdownTextLayoutManager: NSTextLayoutManagerDelegate {

    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                           textLayoutFragmentFor location: any NSTextLocation,
                           in textElement: NSTextElement) -> NSTextLayoutFragment {
        let fragment = CDMarkdownTextLayoutFragment(textElement: textElement,
                                                    range: textElement.elementRange)
        fragment.roundAllCorners = roundAllCorners
        return fragment
    }
}
#endif
```

---

**12.3 — Update `CDMarkdownTextView`**

Replace the monolithic `configure()` with a branched implementation. On iOS 16+, use the `UITextView(frame:usingTextLayoutManager:)` initializer (introduced in iOS 16) to start with a clean TextKit 2 stack, then swap in `CDMarkdownTextLayoutManager`. On iOS 15, fall back to the existing TextKit 1 path.

In `Source/CDMarkdownTextView.swift`:

*Step 1* — Add the TextKit 2 stored property alongside the existing TextKit 1 one:

```swift
open class CDMarkdownTextView: UITextView {

    // TextKit 1 path (iOS 15)
    open var customLayoutManager: CDMarkdownLayoutManager!

    // TextKit 2 path (iOS 16+) — accessed via UITextView.textLayoutManager
    // No separate stored property needed; use textLayoutManager directly.

    open var roundAllCorners: Bool = false {
        didSet {
            if #available(iOS 16.0, tvOS 16.0, *),
               let tk2Manager = textLayoutManager as? CDMarkdownTextLayoutManager {
                tk2Manager.roundAllCorners = roundAllCorners
            } else {
                customLayoutManager?.roundAllCorners = roundAllCorners
            }
        }
    }
```

*Step 2* — Split `configure()` into a TK1 branch and a TK2 branch:

```swift
    open func configure() {
        if #available(iOS 16.0, tvOS 16.0, *) {
            configureTK2()
        } else {
            configureTK1()
        }
        isScrollEnabled = true
        isSelectable = false
        #if os(iOS)
        isEditable = false
        #endif
    }

    // Called on iOS 16+ — no TK1 compat-mode warning produced.
    @available(iOS 16.0, tvOS 16.0, *)
    private func configureTK2() {
        let tk2Manager = CDMarkdownTextLayoutManager.makeDefault()
        // Replace UITextView's default NSTextLayoutManager
        tk2Manager.textContainer = textContainer
        // textLayoutManager is a settable stored property on UITextView (iOS 16+)
        // Assign via the UITextView API to avoid touching the TK1 bridge:
        setValue(tk2Manager, forKey: "textLayoutManager")
    }

    // Called on iOS 15 — deliberately opts into TK1 compatibility mode.
    // The one-time console warning this produces is expected on iOS 16+.
    private func configureTK1() {
        textStorage.removeLayoutManager(layoutManager)
        customLayoutManager = CDMarkdownLayoutManager()
        textStorage.addLayoutManager(customLayoutManager)
        customLayoutManager.addTextContainer(textContainer)
    }
```

*Step 3* — Add a TextKit 2–aware factory for programmatic construction on iOS 16+. When using `init(frame:textContainer:)` the text view starts with its default stack; the `configure()` call in `init?(coder:)` handles storyboard instantiation. For programmatic instantiation on iOS 16+, use the dedicated initializer so the TK2 stack is created from scratch rather than replacing an existing TK1 stack:

```swift
    /// Preferred factory for programmatic use on iOS 16+.
    /// Falls back to the standard initializer on iOS 15.
    @MainActor
    static func makeTextView(frame: CGRect) -> CDMarkdownTextView {
        if #available(iOS 16.0, tvOS 16.0, *) {
            // usingTextLayoutManager: true ensures UITextView creates a TK2 stack.
            // Replacing textLayoutManager afterwards is then a clean swap.
            let view = CDMarkdownTextView(frame: frame, usingTextLayoutManager: true)
            view.configure()
            return view
        } else {
            let view = CDMarkdownTextView(frame: frame, textContainer: nil)
            view.configure()
            return view
        }
    }
```

> **Caution**: The `setValue(_:forKey: "textLayoutManager")` KVC call in `configureTK2()` is a
> workaround for the fact that `UITextView.textLayoutManager` is a read-only property in the
> public SDK. The cleaner alternative is to always use `makeTextView(frame:)` (which uses
> `usingTextLayoutManager: true`) and then immediately replace the manager before any layout pass.
> Verify this approach against the Xcode version available at implementation time, as Apple may
> have provided a public setter by then.

---

**12.4 — Update `CDMarkdownLabel` (deferred)**

`CDMarkdownLabel` draws text via an explicit `NSLayoutManager` owned by `CDMarkdownTextStorage`. This is a standalone TextKit 1 stack — it is not connected to a `UITextView`, so accessing it does **not** trigger the UITextView compat-mode warning. The label migration can therefore be deferred to a later minor release (v4.1+).

When the label is eventually migrated, the drawing loop in `CDMarkdownLabel.drawText(in:)` should be replaced with:
1. Allocate an `NSTextContentStorage` backed by the label's `NSTextStorage`.
2. Create a `CDMarkdownTextLayoutManager` (from step 12.2) with a single `NSTextContainer` sized to the label's `bounds`.
3. Call `ensureLayout(for: textLayoutManager.documentRange)`.
4. Enumerate `NSTextLayoutFragment` objects and call `fragment.draw(at:renderingOrigin, in: context)` on each.

---

**12.5 — Remove TK1 code if iOS 15 support is dropped**

If a future release raises the deployment floor to iOS 16 / tvOS 16, the `#available` branches and the TextKit 1 fallback path can be removed entirely:

1. Delete `CDMarkdownLayoutManager.swift`.
2. Remove `customLayoutManager` from `CDMarkdownTextView`.
3. Simplify `configure()` to call only `configureTK2()`.
4. Remove the `else` branches from `roundAllCorners` and any other `#available(iOS 16, *)` guards.
5. Update `Package.swift` and the podspec to `iOS(.v16)` / `tvOS(.v16)`.

---

**12.6 — Verify**

Run `swift build` and `swift test`. All existing tests must continue to pass.

Manual verification:
- On an **iOS 16+ simulator**: confirm that no "switching to TextKit 1 compatibility mode" message appears in the console when a `CDMarkdownTextView` is displayed or assigned `attributedText`.
- On an **iOS 15 simulator** (requires Xcode with iOS 15 SDK): confirm the TextKit 1 fallback renders correctly — code blocks, syntax blocks, and rounded corners all render as expected.
- Confirm `roundAllCorners = true` on a `CDMarkdownTextView` still draws rounded backgrounds on code and syntax spans on both OS versions.

---

## 13. DocC Documentation

CDMarkdownKit currently generates API documentation with Jazzy. This section adds a native DocC catalog so the docs integrate with Xcode's documentation browser, support Apple's tutorial format, and can be exported as a static site (replacing or complementing the Jazzy-generated `docs/`).

**Prerequisite**: Section 9 (Jazzy doc comments) must be complete. The `///` comments added in step 9.2 are already valid DocC markup — no re-writing is needed, only augmentation with DocC-specific directives where useful.

### Steps

---

**13.1 — Create the DocC catalog**

Create the folder `Source/CDMarkdownKit.docc/`. SPM automatically detects a `.docc` bundle inside the target's source path and compiles it alongside the module.

Inside `Source/CDMarkdownKit.docc/`, create `Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>CDMarkdownKit</string>
    <key>CFBundleIdentifier</key>
    <string>me.christopherdehaan.CDMarkdownKit</string>
    <key>CFBundleVersion</key>
    <string>3.0.0</string>
</dict>
</plist>
```

---

**13.2 — Add the top-level landing page**

Create `Source/CDMarkdownKit.docc/CDMarkdownKit.md`. This file is the root article that DocC uses as the module landing page. Its title must match the module name exactly.

```markdown
# ``CDMarkdownKit``

A pure-Swift, zero-dependency framework for parsing Markdown text into `NSAttributedString`.

## Overview

CDMarkdownKit converts Markdown input into a fully attributed `NSAttributedString` in three phases:
escaping, element parsing, and unescaping. The result can be rendered in any `UILabel`,
`UITextView`, or the provided ``CDMarkdownLabel`` and ``CDMarkdownTextView`` subclasses,
which add rounded-corner background styling for code and syntax blocks.

## Topics

### Getting Started

- <doc:GettingStarted>

### Parsing

- ``CDMarkdownParser``

### Markdown Elements

- ``CDMarkdownBold``
- ``CDMarkdownItalic``
- ``CDMarkdownHeader``
- ``CDMarkdownList``
- ``CDMarkdownOrderedList``
- ``CDMarkdownQuote``
- ``CDMarkdownLink``
- ``CDMarkdownAutomaticLink``
- ``CDMarkdownImage``
- ``CDMarkdownCode``
- ``CDMarkdownSyntax``
- ``CDMarkdownStrikethrough``
- ``CDMarkdownTable``

### Protocols

- ``CDMarkdownElement``
- ``CDMarkdownStyle``
- ``CDMarkdownCommonElement``
- ``CDMarkdownLevelElement``
- ``CDMarkdownLinkElement``

### UI Components

- ``CDMarkdownLabel``
- ``CDMarkdownTextView``
- ``CDMarkdownLayoutManager``

### Cross-Platform Types

- ``CDFont``
- ``CDColor``
- ``CDImage``
```

---

**13.3 — Add the Getting Started article**

Create `Source/CDMarkdownKit.docc/GettingStarted.md`:

```markdown
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
```

---

**13.4 — Audit and extend doc comments**

Open each public source file and verify the following rules:

1. **Every `public` / `open` declaration has at least one `///` line.** Step 9.2 covered the minimum set; fill any gaps now.
2. **Parameters and return values are documented** for non-trivial methods. Use DocC's parameter list syntax:

```swift
/// Parses a Markdown string and returns a styled attributed string.
///
/// - Parameter string: The raw Markdown input.
/// - Returns: An `NSAttributedString` with attributes applied for all recognized Markdown syntax.
public func parse(_ string: String) -> NSAttributedString
```

3. **Cross-references use double-backtick links** where helpful (e.g., `/// See ``CDMarkdownStyle`` for styling options.`). DocC resolves these at build time and warns on broken links.

4. **Do not add comments where the declaration is self-explanatory.** A `var font: CDFont?` on a style element needs no comment beyond what the protocol already says.

Focus effort on:
- `CDMarkdownParser` — `init`, both `parse` overloads, `customElements`, `squashNewlines`, `automaticLinkDetectionEnabled`
- `CDMarkdownElement` protocol requirements (`regex`, `regularExpression()`, `match(_:attributedString:)`)
- `CDMarkdownStyle` protocol properties
- `CDMarkdownLabel` and `CDMarkdownTextView` public surface

---

**13.5 — Wire DocC into Package.swift**

DocC catalog compilation is automatic when the `.docc` bundle is inside the target's path. Verify the existing `target` entry in `Package.swift` does not have an `exclude:` entry that would suppress `CDMarkdownKit.docc/`:

```swift
.target(
    name: "CDMarkdownKit",
    path: "Source",
    exclude: ["Info.plist"],   // CDMarkdownKit.docc/ must NOT be listed here
    resources: [.process("PrivacyInfo.xcprivacy")],
    ...
)
```

Run `swift build` and confirm there are no DocC compilation warnings.

---

**13.6 — Build and preview the documentation**

From the repo root:

```bash
# Build the DocC archive
swift package generate-documentation --target CDMarkdownKit

# Preview locally in a browser (requires Xcode Command Line Tools)
swift package --disable-sandbox preview-documentation --target CDMarkdownKit
```

Open the URL printed by `preview-documentation` (typically `http://localhost:8080`) and verify:
- The landing page lists all topic groups
- The Getting Started article renders correctly
- Symbol links (double-backtick references) resolve without warnings

---

**13.7 — Export a static site**

To replace or supplement the Jazzy-generated `docs/` folder with a DocC static site:

```bash
swift package --disable-sandbox generate-documentation \
    --target CDMarkdownKit \
    --output-path docs \
    --transform-for-static-hosting \
    --hosting-base-path CDMarkdownKit
```

The `--hosting-base-path` value must match the GitHub Pages subpath (`/CDMarkdownKit` for a project page at `https://chrisdhaan.github.io/CDMarkdownKit/`).

Commit the updated `docs/` directory. GitHub Pages will serve the DocC site automatically once the existing Pages configuration (set up in step 9.4) is in place.

> **Note**: If both Jazzy and DocC outputs coexist in `docs/`, the DocC static site should be placed in a subdirectory (e.g., `docs/docc/`) and linked from the Jazzy index page until a full cutover is made.

---

**13.8 — Add DocC to CI**

In `.github/workflows/ci.yml`, add a documentation build job that runs on the SPM runner:

```yaml
documentation:
  name: DocC Build
  runs-on: macos-15
  timeout-minutes: 10
  steps:
    - uses: actions/checkout@v4
    - name: Build DocC
      run: swift package generate-documentation --target CDMarkdownKit 2>&1 | tee docc.log
    - name: Fail on DocC warnings
      run: grep -q "warning:" docc.log && exit 1 || exit 0
```

The "Fail on DocC warnings" step treats unresolved symbol links as build failures, preventing documentation rot as the API evolves.

---

**13.9 — Verify**

Run `swift build` and confirm no DocC warnings are emitted. Run `swift test` to confirm the catalog did not disturb the test target. Open Xcode, select the `CDMarkdownKit` scheme, and choose **Product → Build Documentation** to verify the docs appear in Xcode's documentation browser under "CDMarkdownKit".

---

## 14. visionOS Target

Add first-class visionOS support to CDMarkdownKit. visionOS uses UIKit (UIFont, UIColor, UIImage, UILabel, UITextView), so it slots into the existing `os(iOS) || os(tvOS)` / `os(iOS) || os(tvOS) || os(watchOS)` platform guards throughout the source — no new abstractions are required. The UI components (`CDMarkdownLabel`, `CDMarkdownTextView`, `CDMarkdownLayoutManager`) are compatible with visionOS as-is; `CDMarkdownImage` also applies since `UIImage` is available.

The minimum visionOS version expressible in SPM without deprecation warnings is **visionOS 1.0**.

Complete sections 3 and 4 before starting this section.

---

**14.1 — Update `Package.swift`**

Add `.visionOS(.v1)` to the platforms array:

```swift
platforms: [.iOS(.v12),
            .macOS(.v10_13),
            .tvOS(.v12),
            .watchOS(.v4),
            .visionOS(.v1)],
```

Run `swift build` to confirm the package resolves cleanly on visionOS.

---

**14.2 — Update `CDMarkdownKit.podspec`**

Add the visionOS deployment target alongside the existing platform entries:

```ruby
s.visionos.deployment_target = '1.0'
```

Run `bundle exec pod lib lint --allow-warnings` to confirm the podspec is valid.

---

**14.3 — Update platform guards in Source files**

visionOS must be added to every `#if` condition that currently gates UIKit-dependent code. The two distinct guard patterns in the source tree are:

**Pattern A** — `#if os(iOS) || os(tvOS) || os(watchOS)` (UIFont / UIColor / UIImage typealias and UIKit imports)

Add `|| os(visionOS)` to each occurrence. Affected files:

- `CDColor.swift`
- `CDColor+CDMarkdownKit.swift`
- `CDFont.swift`
- `CDFont+CDMarkdownKit.swift`
- `CDImage.swift`
- `CDImage+CDMarkdownKit.swift`
- `CDMarkdownAutomaticLink.swift`
- `CDMarkdownBold.swift`
- `CDMarkdownCode.swift`
- `CDMarkdownCodeEscaping.swift`
- `CDMarkdownCommonElement.swift`
- `CDMarkdownEscaping.swift`
- `CDMarkdownHeader.swift`
- `CDMarkdownItalic.swift`
- `CDMarkdownLink.swift`
- `CDMarkdownList.swift`
- `CDMarkdownQuote.swift`
- `CDMarkdownStrikethrough.swift`
- `CDMarkdownSyntax.swift`
- `CDMarkdownUnescaping.swift`

Updated guard:

```swift
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
```

**Pattern B** — `#if os(iOS) || os(tvOS)` (UILabel / UITextView / NSLayoutManager — UI layer only)

Add `|| os(visionOS)` to each occurrence. Affected files:

- `CDMarkdownImage.swift` (import guard, line ~28)
- `CDMarkdownLayoutManager.swift`
- `CDMarkdownLabel.swift`
- `CDMarkdownTextView.swift`
- `NSTextStorage+CDMarkdownKit.swift`

Updated guard:

```swift
#if os(iOS) || os(tvOS) || os(visionOS)
```

**Pattern C** — `#if os(iOS) || os(macOS) || os(tvOS)` (image resolution in `CDMarkdownImage.swift`, line ~34)

Add `|| os(visionOS)`:

```swift
#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
```

After updating all guards, run `swift build` and confirm no compilation errors on any platform.

---

**14.4 — Add a visionOS scheme and target in Xcode**

Open `CDMarkdownKit.xcodeproj` in Xcode and add a visionOS framework target:

1. **File → New → Target** → choose **Framework** under the visionOS tab.
2. Name it `CDMarkdownKit visionOS`. Set the deployment target to **visionOS 1.0**.
3. In **Build Phases → Compile Sources**, add all files from `Source/` (the same set as the iOS target).
4. Remove the auto-generated stub file Xcode creates.
5. In **Build Phases**, add a **Run Script** phase identical to the existing Swift Lint phases:

```bash
export PATH="$PATH:/opt/homebrew/bin"
if which swiftlint >/dev/null; then
    cd "$SRCROOT" && swiftlint lint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

6. **Product → Scheme → Manage Schemes** — confirm `CDMarkdownKit visionOS` is listed and set to **Shared**.
7. Build the scheme in both Debug and Release to confirm there are no errors.

---

**14.5 — Add a visionOS CI job**

In `.github/workflows/ci.yml`, add a `visionOS` job following the same 5-entry matrix pattern used by the other platform jobs on `macos-26`. visionOS simulators are only available on `macos-26`; there are no visionOS runtimes on `macos-15`.

```yaml
visionOS:
  name: Test ${{ matrix.name }}
  runs-on: ${{ matrix.runner }}
  timeout-minutes: 10
  strategy:
    fail-fast: false
    matrix:
      include:
        - runner: macos-26
          xcode: /Applications/Xcode_26.4.1.app/Contents/Developer
          destination: "OS=26.4,name=Apple Vision Pro"
          name: "visionOS 26 (Xcode 26.4.1)"
        - runner: macos-26
          xcode: /Applications/Xcode_26.3.app/Contents/Developer
          destination: "OS=26.2,name=Apple Vision Pro"
          name: "visionOS 26 (Xcode 26.3)"
        - runner: macos-26
          xcode: /Applications/Xcode_26.2.app/Contents/Developer
          destination: "OS=26.2,name=Apple Vision Pro"
          name: "visionOS 26 (Xcode 26.2)"
        - runner: macos-26
          xcode: /Applications/Xcode_26.1.1.app/Contents/Developer
          destination: "OS=26.1,name=Apple Vision Pro"
          name: "visionOS 26 (Xcode 26.1.1)"
        - runner: macos-26
          xcode: /Applications/Xcode_26.0.1.app/Contents/Developer
          destination: "OS=26.0,name=Apple Vision Pro"
          name: "visionOS 26 (Xcode 26.0.1)"
  steps:
    - uses: actions/checkout@v4
    - name: Select Xcode
      run: sudo xcode-select -s ${{ matrix.xcode }}
    - name: Install xcbeautify
      run: brew install xcbeautify
    - name: ${{ matrix.name }} - Debug
      run: |
        set -o pipefail
        env NSUnbufferedIO=YES xcodebuild -project "CDMarkdownKit.xcodeproj" -scheme "CDMarkdownKit visionOS" -destination "${{ matrix.destination }}" -configuration Debug clean build 2>&1 | xcbeautify --renderer github-actions
    - name: ${{ matrix.name }} - Release
      run: |
        set -o pipefail
        env NSUnbufferedIO=YES xcodebuild -project "CDMarkdownKit.xcodeproj" -scheme "CDMarkdownKit visionOS" -destination "${{ matrix.destination }}" -configuration Release clean build 2>&1 | xcbeautify --renderer github-actions
```

> **Note**: Verify the exact OS versions and device name against the current `macos-26` runner image spec in `actions/runner-images` before merging, as simulator runtimes are updated with each runner image release. Xcode 26.3 has no matching 26.3 runtime and uses the 26.2 runtime instead.

---

**14.6 — Update `README.md`**

Add visionOS to the requirements table:

```markdown
| visionOS | 1.0+ | 5.3+ | SPM, CocoaPods |
```

---

**14.7 — Verify**

Run the full verification suite:

```bash
# SPM build
swift build

# Unit tests
swift test

# Confirm no SwiftLint violations
swiftlint lint --strict
```

Open Xcode and build the `CDMarkdownKit visionOS` scheme in both Debug and Release. Run the app in the visionOS simulator and confirm that `CDMarkdownParser.parse(_:)` returns a correctly styled `NSAttributedString` and that `CDMarkdownLabel` renders text without layout errors.
