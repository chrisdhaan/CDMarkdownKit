<p align="center">
    <img src="Documentation/cdmarkdownkit.png" alt="CDMarkdownKit" width="850" />
</p>

<p align="center">
    <a href="https://github.com/chrisdhaan/CDMarkdownKit/actions/workflows/ci.yml">
        <img src="https://github.com/chrisdhaan/CDMarkdownKit/actions/workflows/ci.yml/badge.svg" alt="CI Status">
    </a>
    <a href="https://www.swift.org">
        <img src="https://img.shields.io/badge/Swift-5.3%2B-orange?style=flat" alt="Swift Versions">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/p/CDMarkdownKit.svg?style=flat" alt="Platforms">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/v/CDMarkdownKit.svg?style=flat" alt="CocoaPods Compatible">
    </a>
    <a href="https://www.swift.org/package-manager">
        <img src="https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat" alt="Swift Package Manager Compatible">
    </a>
    <a href="http://cocoapods.org/pods/CDMarkdownKit">
        <img src="https://img.shields.io/cocoapods/l/CDMarkdownKit.svg?style=flat" alt="License">
    </a>
</p>

---

A pure-Swift, zero-dependency framework for parsing Markdown text into styled `NSAttributedString`.

## Features

- [x] Parse Markdown to styled `NSAttributedString`
- [x] Support for bold, italic, strikethrough, headers, lists, quotes, code blocks
- [x] Clickable links and automatic URL detection
- [x] Image rendering (iOS, macOS, tvOS)
- [x] Async image loading with `async/await`
- [x] Custom Markdown elements
- [x] `UILabel` and `UITextView` subclasses with Markdown support
- [x] Swift 6 concurrency safety

## Quick Example

```swift
import CDMarkdownKit

let parser = CDMarkdownParser()
let markdown = "# Hello **World**\n\nThis is *italic* text."
let attributedString = parser.parse(markdown)
label.attributedText = attributedString
```

## Requirements

| Platform | Minimum OS | Swift | Installation |
|----------|-----------|-------|--------------|
| iOS      | 15.0+     | 5.3+  | SPM, CocoaPods |
| macOS    | 12.0+     | 5.3+  | SPM, CocoaPods |
| tvOS     | 15.0+     | 5.3+  | SPM, CocoaPods |
| watchOS  | 8.0+      | 5.3+  | SPM, CocoaPods |

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/chrisdhaan/CDMarkdownKit.git", from: "3.0.0")
```

Or in Xcode: **File → Add Packages** and enter the repository URL.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CDMarkdownKit', '~> 3.0'
```

Run `pod install`.

## Usage

For comprehensive usage documentation including styling, custom elements, and platform-specific information, see [Documentation/Usage.md](Documentation/Usage.md).

## Contributing

We welcome contributions! Before contributing to CDMarkdownKit, please read the detailed instructions in our [contribution guide](CONTRIBUTING.md). We maintain high standards for code quality and test coverage, and we're happy to help you get your changes integrated.

---

## License

CDMarkdownKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
