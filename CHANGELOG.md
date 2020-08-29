# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

#### 2.x Releases
- `2.0.x` Releases - [2.0.0](#200)

#### 1.x Releases
- `1.2.x` Releases - [1.2.0](#120) | [1.2.1](#121)
- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100)

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
