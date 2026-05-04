# Change Log
All notable changes to this project will be documented in this file.
`CDMarkdownKit` adheres to [Semantic Versioning](https://semver.org/).

## Table of Contents

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

## [2.5.1](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.5.1)

Released on 2022-12-13.

### Added

- Swift 5.7

### Updated

- CI: Tests device, platform, Xcode, and SDK versions

---

## [2.5.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.5.0)

Released on 2022-12-12.

### Added

- Underline color and style on all elements

---

## [2.4.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.4.0)

Released on 2022-12-03.

### Added

- Strikethrough

---

## [2.3.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.3.0)

Released on 2022-10-17.

### Added

- `squashNewlines` parameter

---

## [2.2.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.2.0)

Released on 2022-06-26.

### Added

- Swift 5.4, 5.5, and 5.6

### Updated

- Swift Package Manager: Minimum Swift version 5.3
- CI: Tests device, platform, Xcode, and SDK versions

---

## [2.1.1](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.1.1)

Released on 2021-05-29.

### Updated

- Markdown Parsing: Bold and italic parsing by character
- Swift Package Manager: Built with `swift-tools-version:5.1`

---

## [2.1.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.1.0)

Released on 2020-08-30.

### Added

- Swift 5.1

---

## [2.0.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/2.0.0)

Released on 2020-08-29.

### Added

- Swift 5.0

---

## [1.2.1](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/1.2.1)

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

## [1.2.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/1.2.0)

Released on 2018-07-27.

### Added

- Platform Support: macOS: `CDFont+CDMarkdownKit` `withSize` method that uses `NSFontManager` to correctly set system fonts dynamically based on size
- Swift 4.0: `CDAttributesKey` for correctly configuring `NSAttributedString` attribute dictionary keys
- SwiftLint

### Updated

- UITextView With Markdown Formatting: Code example to use `NSLayoutConstraints` to correctly set `intrinsicContentSize`
- Platform Support: macOS: `CDFont+CDMarkdownKit` `bold` and `italic` methods to use `NSFontManager` opposed to `CDFontDescriptorSymbolicTraits`

---

## [1.1.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/1.1.0)

Released on 2018-06-12.

### Added

- Swift 4.0

---

## [1.0.0](https://github.com/christopherdehaan/CDMarkdownKit/releases/tag/1.0.0)

Released on 2018-06-11.

### Added

- Markdown Parsing: Italic, Bold, Header, Quote, List, Code, Syntax, Link, Image
- UITextView With Markdown Formatting
- UILabel With Markdown Formatting
- Platform Support: iOS, macOS, tvOS, watchOS
- Documentation

---
