# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

#### 2.x Releases
- `2.5.x` Releases - [2.5.0](#250) | [2.5.1](#251)
- `2.4.x` Releases - [2.4.0](#240)
- `2.3.x` Releases - [2.3.0](#230)
- `2.2.x` Releases - [2.2.0](#220)
- `2.1.x` Releases - [2.1.0](#210) | [2.1.1](#211)
- `2.0.x` Releases - [2.0.0](#200)

#### 1.x Releases
- `1.2.x` Releases - [1.2.0](#120) | [1.2.1](#121)
- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100)

---

## [2.5.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.5.1)
## SDK Support
Released on 2022-12-13.

#### Added

- [x] Swift 5.7

#### Updated

- [x] CI
    - [x] Tests device, platform, Xcode, and SDK versions

---

## [2.5.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.5.0)
## Markdown Parsing
Released on 2022-12-12.

#### Added

- [x] Markdown Parsing
    - [x] Underline color and style on all elements

---

## [2.4.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.4.0)
## Markdown Parsing
Released on 2022-12-03.

#### Added

- [x] Markdown Parsing
    - [x] Strikethrough

---

## [2.3.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.3.0)
## Markdown Parsing
Released on 2022-10-17.

#### Added

- [x] Markdown Parsing
    - [x] `squashNewlines` parameter

---

## [2.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.2.0)
## SDK Support
Released on 2022-06-26.

#### Added

- [x] Swift 5.4, 5.5, and 5.6

#### Updated
    
- [x] Swift Package Manager
    - [x] Minimum Swift version 5.3
- [x] CI
    - [x] Tests device, platform, Xcode, and SDK versions

---

## [2.1.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.1.1)
## Bug Fixes
Released on 2021-05-29.

#### Updated

- [x] Markdown Parsing
    - [x] Bold and italic parsing by character
- [x] Swift Package Manager
    - [x] Built with `swift-tools-version:5.1`

---

## [2.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.1.0)
## SDK Support
Released on 2020-08-30.

#### Added

- [x] Swift 5.1

---

## [2.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/2.0.0)
## SDK Support
Released on 2020-08-29.

#### Added

- [x] Swift 5.0

---

## [1.2.1](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.2.1)
## SDK Support
Released on 2018-12-14.

#### Added

- [x] Swift 4.2
- [x] Swift 4.0
    - [x] `Dictionary+CDMarkdownKit`, `NSAttributedString+CDMarkdownKit`, `NSMutableAttributedString+CDMarkdownKit`, `NSTextCheckResult+CDMarkdownKit`, and `NSTextStorage+CDMarkdownKit`extensions
- [x] iOS Example
    - [x] `CDApplicationLaunchOptionsKey`, `CDLayoutConstraintAttribute`, and `CDLayoutConstraintRelation` typealias'

#### Updated

- [x] Swift 4.0
    - [x] Extensions assume responsibility for `switft()` macro from classes
    - [x] `CDAttributesKey` becomes `CDAttributedStringKey`

---

## [1.2.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.2.0)
## SDK Support, Platform Support, UITextView With Markdown Formatting
Released on 2018-07-27.

#### Added

- [x] Platform Support
    - [x] macOS
        - [x] `CDFont+CDMarkdownKit` `withSize` method that uses `NSFontManager` to correctly set system fonts dynamically based on size
- [x] Swift 4.0
    - [x] `CDAttributesKey`  for correctly configuring `NSAttributedString` attribute dictionary keys
- [x] SwiftLint

#### Updated

- [x] UITextView With Markdown Formatting
    - [x] Code example to use `NSLayoutConstraints` to correctly set `intrinsicContentSize`
- [x] Platform Support
    - [x] macOS
        - [x] `CDFont+CDMarkdownKit` `bold` and `italic` methods to use `NSFontManager` opposed to `CDFontDescriptorSymbolicTraits`

---

## [1.1.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.1.0)
## SDK Support
Released on 2018-06-12.

#### Added

- [x] Swift 4.0

---

## [1.0.0](https://github.com/chrisdhaan/CDMarkdownKit/releases/tag/1.0.0)
## Markdown Parsing, UITextView With Markdown Formatting, UILabel With Markdown Formatting, and Platform Support
Released on 2018-06-11.

#### Added

- [x] Markdown Parsing
    - [x] Italic
    - [x] Bold
    - [x] Header
    - [x] Quote
    - [x] List
    - [x] Code
    - [x] Syntax
    - [x] Link
    - [x] Image
- [x] UITextView With Markdown Formatting
- [x] UILabel With Markdown Formatting
- [x] Platform Support
    - [x] iOS
    - [x] macOS
    - [x] tvOS
    - [x] watchOS
- [x] Documentation

---
